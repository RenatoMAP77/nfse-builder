"""
4_deploy_to_sap.py
Deploy opcional: lê os .clas.abap de municipios_novos/ e cria/atualiza as classes
diretamente no SAP via API REST do ADT.

Uso:
  python 4_deploy_to_sap.py [--only sc4202305] [--yes] [--transport SRTK123456]
  --only:      processa apenas a classe com esse sufixo (ex: sc4202305)
  --yes:       pula confirmação interativa
  --transport: número do transporte SAP (ex: SRTK123456); se omitido, usa $TMP

Variáveis de ambiente (opcional, usa .mcp.json como fallback):
  SAP_URL, SAP_USER, SAP_PASSWORD, SAP_CLIENT
"""
import json
import re
import sys
import urllib.parse
from pathlib import Path

import requests

BASE_DIR = Path(__file__).parent.parent
INPUT_DIR = BASE_DIR / "municipios_novos"
MCP_JSON = BASE_DIR / ".mcp.json"

SAP_PACKAGE = "/S4TAX/NFSE"
DEFAULT_TRANSPORT = "$TMP"


# ---------------------------------------------------------------------------
# Configuração SAP
# ---------------------------------------------------------------------------

def load_sap_config() -> dict:
    """Carrega configuração SAP do .mcp.json ou variáveis de ambiente."""
    import os

    config = {
        "url": os.environ.get("SAP_URL"),
        "user": os.environ.get("SAP_USER"),
        "password": os.environ.get("SAP_PASSWORD"),
        "client": os.environ.get("SAP_CLIENT", "400"),
    }

    # Fallback: lê do .mcp.json
    if not all([config["url"], config["user"], config["password"]]):
        if MCP_JSON.exists():
            with open(MCP_JSON, encoding="utf-8") as f:
                mcp = json.load(f)
            adt_env = mcp.get("mcpServers", {}).get("abap-adt", {}).get("env", {})
            config["url"] = config["url"] or adt_env.get("SAP_URL", "")
            config["user"] = config["user"] or adt_env.get("SAP_USER", "")
            config["password"] = config["password"] or adt_env.get("SAP_PASSWORD", "")
            config["client"] = config["client"] or adt_env.get("SAP_CLIENT", "400")

    missing = [k for k, v in config.items() if not v]
    if missing:
        print(f"ERRO: Configuração SAP incompleta. Faltam: {missing}")
        print("  Configure via variáveis de ambiente ou no .mcp.json")
        sys.exit(1)

    return config


# ---------------------------------------------------------------------------
# Cliente SAP ADT
# ---------------------------------------------------------------------------

class SapAdtClient:
    """Cliente simples para a API REST do SAP ADT."""

    def __init__(self, url: str, user: str, password: str, client: str):
        self.base_url = url.rstrip("/")
        self.auth = (user, password)
        self.client = client
        self.session = requests.Session()
        self.session.auth = self.auth
        self.session.headers.update({
            "sap-client": client,
            "Accept": "application/xml",
        })
        self._csrf_token = None

    def _fetch_csrf(self):
        """Obtém token CSRF necessário para operações de escrita."""
        resp = self.session.get(
            f"{self.base_url}/sap/bc/adt/discovery",
            headers={"X-CSRF-Token": "Fetch"},
            timeout=15,
        )
        resp.raise_for_status()
        self._csrf_token = resp.headers.get("X-CSRF-Token", "")
        return self._csrf_token

    def _get_csrf(self) -> str:
        if not self._csrf_token:
            self._fetch_csrf()
        return self._csrf_token

    def _write_headers(self) -> dict:
        return {"X-CSRF-Token": self._get_csrf()}

    def class_exists(self, class_name: str) -> bool:
        """Verifica se a classe já existe no SAP."""
        encoded = urllib.parse.quote(class_name, safe="")
        resp = self.session.get(
            f"{self.base_url}/sap/bc/adt/oo/classes/{encoded}",
            timeout=15,
        )
        return resp.status_code == 200

    def create_class(
        self,
        class_name: str,
        description: str,
        package: str,
        transport: str,
    ) -> requests.Response:
        """Cria a classe ABAP no SAP."""
        # Nome em maiúsculas para o SAP
        class_upper = class_name.upper()

        # Package: se for $TMP não precisa de transporte
        corr_param = f"&corrNr={transport}" if not transport.startswith("$") else ""

        xml_body = f"""<?xml version="1.0" encoding="utf-8"?>
<oo:class xmlns:oo="http://www.sap.com/adt/oo"
          xmlns:adtcore="http://www.sap.com/adt/core"
          adtcore:description="{description}"
          adtcore:language="PT"
          adtcore:name="{class_upper}"
          adtcore:masterLanguage="PT">
  <adtcore:packageRef adtcore:name="{package}"/>
</oo:class>"""

        headers = {
            **self._write_headers(),
            "Content-Type": "application/vnd.sap.adt.oo.classes.v4+xml; charset=utf-8",
        }

        resp = self.session.post(
            f"{self.base_url}/sap/bc/adt/oo/classes?{'corrNr=' + transport + '&' if corr_param else ''}",
            data=xml_body.encode("utf-8"),
            headers=headers,
            timeout=30,
        )
        return resp

    def lock_object(self, class_name: str) -> str:
        """
        Trava o objeto para edição.
        Retorna o lockHandle necessário para unlock e escrita.
        """
        encoded = urllib.parse.quote(class_name.upper(), safe="")
        headers = {
            **self._write_headers(),
            "X-SAP-Lock-Expire": "PT30M",
        }
        resp = self.session.post(
            f"{self.base_url}/sap/bc/adt/oo/classes/{encoded}/locks?_action=LOCK&accessMode=MODIFY",
            headers=headers,
            timeout=15,
        )
        resp.raise_for_status()
        data = resp.json() if resp.content else {}
        lock_handle = data.get("com.sap.adt.lock.v1:lockHandle", {}).get("com.sap.adt.lock.v1:lockHandleId", "")
        if not lock_handle:
            # Tenta extrair do XML ou do header
            lock_handle = resp.headers.get("X-SAP-Lock-Handle", "")
        return lock_handle

    def write_main_source(
        self,
        class_name: str,
        source_code: str,
        lock_handle: str,
        transport: str,
    ) -> requests.Response:
        """Envia o código-fonte para o include principal (CCDEF+CCIMP+CCMAC+CCAU)."""
        encoded = urllib.parse.quote(class_name.upper(), safe="")
        headers = {
            **self._write_headers(),
            "Content-Type": "text/plain; charset=utf-8",
            "X-SAP-Lock-Handle": lock_handle,
        }
        if not transport.startswith("$"):
            headers["X-SAP-Corr-Id"] = transport

        resp = self.session.put(
            f"{self.base_url}/sap/bc/adt/oo/classes/{encoded}/source/main",
            data=source_code.encode("utf-8"),
            headers=headers,
            timeout=30,
        )
        return resp

    def unlock_object(self, class_name: str, lock_handle: str):
        """Libera o lock do objeto."""
        encoded = urllib.parse.quote(class_name.upper(), safe="")
        headers = self._write_headers()
        self.session.delete(
            f"{self.base_url}/sap/bc/adt/oo/classes/{encoded}/locks/{lock_handle}",
            headers=headers,
            timeout=15,
        )

    def activate(self, class_name: str) -> requests.Response:
        """Ativa a classe no SAP."""
        class_upper = class_name.upper()
        encoded = urllib.parse.quote(class_upper, safe="")

        xml_body = f"""<?xml version="1.0" encoding="utf-8"?>
<adtcore:objectReferences xmlns:adtcore="http://www.sap.com/adt/core">
  <adtcore:objectReference adtcore:name="{class_upper}"
                           adtcore:type="CLAS/OC"
                           adtcore:uri="/sap/bc/adt/oo/classes/{encoded}"/>
</adtcore:objectReferences>"""

        headers = {
            **self._write_headers(),
            "Content-Type": "application/vnd.sap.adt.activation.request+xml; charset=utf-8",
        }
        resp = self.session.post(
            f"{self.base_url}/sap/bc/adt/activation",
            data=xml_body.encode("utf-8"),
            headers=headers,
            timeout=60,
        )
        return resp


# ---------------------------------------------------------------------------
# Lógica de deploy
# ---------------------------------------------------------------------------

def extract_class_name_from_file(abap_path: Path) -> str | None:
    """Extrai o nome da classe do arquivo .clas.abap."""
    content = abap_path.read_text(encoding="utf-8", errors="ignore")
    m = re.search(r"CLASS\s+(/s4tax/\S+)\s+DEFINITION", content, re.IGNORECASE)
    return m.group(1).lower() if m else None


def deploy_class(
    client: SapAdtClient,
    abap_path: Path,
    transport: str,
    yes: bool,
) -> dict:
    """Faz o deploy de uma classe no SAP. Retorna dict com status."""
    result = {"file": abap_path.name, "status": "error", "error": None}

    class_name = extract_class_name_from_file(abap_path)
    if not class_name:
        result["error"] = "Não foi possível extrair nome da classe do arquivo"
        return result

    # Extrai sufixo UF+IBGE do nome do arquivo: #s4tax#nfse_sc4202305.clas.abap
    m = re.search(r"nfse_([a-z]{2}\d+)", abap_path.stem)
    city_suffix = m.group(1) if m else abap_path.stem

    source_code = abap_path.read_text(encoding="utf-8")

    # Confirmação
    exists = client.class_exists(class_name)
    action = "ATUALIZAR" if exists else "CRIAR"
    package_info = f"pacote {SAP_PACKAGE}, transporte {transport}"

    print(f"\n  Classe: {class_name.upper()}")
    print(f"  Ação: {action} ({package_info})")

    if not yes:
        resp = input("  Confirmar? [s/N] ").strip().lower()
        if resp not in ("s", "sim", "y", "yes"):
            print("  [PULADO] Confirmação negada.")
            result["status"] = "skipped"
            return result

    try:
        # Criar se não existir
        if not exists:
            desc = f"NFS-e {city_suffix.upper()[:25]}"
            create_resp = client.create_class(class_name, desc, SAP_PACKAGE, transport)
            if create_resp.status_code not in (200, 201):
                result["error"] = (
                    f"Erro ao criar classe (HTTP {create_resp.status_code}): "
                    f"{create_resp.text[:300]}"
                )
                return result
            print(f"  Classe criada.")

        # Lock
        lock_handle = client.lock_object(class_name)
        if not lock_handle:
            result["error"] = "Não foi possível obter lock para edição"
            return result

        # Upload fonte
        write_resp = client.write_main_source(class_name, source_code, lock_handle, transport)

        # Unlock (sempre)
        client.unlock_object(class_name, lock_handle)

        if write_resp.status_code not in (200, 201, 204):
            result["error"] = (
                f"Erro ao enviar fonte (HTTP {write_resp.status_code}): "
                f"{write_resp.text[:300]}"
            )
            return result

        print(f"  Fonte enviado.")

        # Activate
        act_resp = client.activate(class_name)
        if act_resp.status_code not in (200, 201, 204):
            result["error"] = (
                f"Erro ao ativar (HTTP {act_resp.status_code}): "
                f"{act_resp.text[:300]}"
            )
            return result

        print(f"  [OK] Ativado com sucesso.")
        result["status"] = "deployed"

    except Exception as e:
        result["error"] = f"Exceção: {e}"

    return result


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    only = None
    yes = "--yes" in sys.argv
    transport = DEFAULT_TRANSPORT

    if "--only" in sys.argv:
        idx = sys.argv.index("--only")
        if idx + 1 < len(sys.argv):
            only = sys.argv[idx + 1]

    if "--transport" in sys.argv:
        idx = sys.argv.index("--transport")
        if idx + 1 < len(sys.argv):
            transport = sys.argv[idx + 1]

    if not INPUT_DIR.exists():
        print(f"ERRO: Pasta {INPUT_DIR} não encontrada.")
        print("  Execute primeiro: python run_municipios.py")
        sys.exit(1)

    abap_files = [
        f for f in sorted(INPUT_DIR.glob("*.clas.abap"))
        if not f.name.endswith(".invalid")
    ]

    if not abap_files:
        print(f"Nenhum arquivo .clas.abap encontrado em {INPUT_DIR}")
        sys.exit(0)

    if only:
        abap_files = [f for f in abap_files if only in f.name]
        if not abap_files:
            print(f"ERRO: Nenhum arquivo encontrado com '{only}' no nome.")
            sys.exit(1)

    print(f"Deploy de {len(abap_files)} classe(s) → SAP {SAP_PACKAGE}")
    print(f"Transporte: {transport}")

    config = load_sap_config()
    client = SapAdtClient(
        url=config["url"],
        user=config["user"],
        password=config["password"],
        client=config["client"],
    )

    # Testa conexão
    print("\nTestando conexão SAP...")
    try:
        client._fetch_csrf()
        print(f"  Conectado: {config['url']} (usuário: {config['user']})")
    except Exception as e:
        print(f"  ERRO de conexão: {e}")
        sys.exit(1)

    results = []
    for abap_path in abap_files:
        print(f"\n→ {abap_path.name}")
        r = deploy_class(client, abap_path, transport, yes)
        results.append(r)
        if r.get("error"):
            print(f"  [ERRO] {r['error']}")

    # Relatório
    deployed = [r for r in results if r["status"] == "deployed"]
    skipped = [r for r in results if r["status"] == "skipped"]
    errors = [r for r in results if r["status"] == "error"]

    print("\n" + "=" * 60)
    print(f"DEPLOY: {len(deployed)} OK | {len(skipped)} pulados | {len(errors)} erros")
    print("=" * 60)

    if errors:
        sys.exit(1)


if __name__ == "__main__":
    main()
