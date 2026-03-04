"""
1_scrape_ibge.py
Faz scraping do site do IBGE e salva os códigos dos municípios em ibge_codes.json.
Uso: python 1_scrape_ibge.py [--force]
  --force: recria o cache mesmo se já existir
"""
import json
import sys
import unicodedata
from pathlib import Path

import requests
from bs4 import BeautifulSoup

IBGE_URL = "https://www.ibge.gov.br/explica/codigos-dos-municipios.php"
OUTPUT_FILE = Path(__file__).parent / "ibge_codes.json"


def normalize(name: str) -> str:
    """Remove acentos e converte para lowercase para comparação fuzzy."""
    nfkd = unicodedata.normalize("NFKD", name)
    ascii_str = "".join(c for c in nfkd if not unicodedata.combining(c))
    return ascii_str.lower().strip()


def scrape_ibge() -> dict[str, dict[str, str]]:
    """
    Retorna dicionário no formato:
      { "SC": { "cacador": "4202305", "florianopolis": "4205407", ... }, ... }
    """
    print(f"Buscando dados do IBGE em {IBGE_URL} ...")
    headers = {
        "User-Agent": (
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
            "AppleWebKit/537.36 (KHTML, like Gecko) "
            "Chrome/120.0.0.0 Safari/537.36"
        )
    }
    response = requests.get(IBGE_URL, headers=headers, timeout=30)
    response.raise_for_status()

    soup = BeautifulSoup(response.text, "lxml")
    tables = soup.find_all("table", class_="container-uf")

    if not tables:
        raise RuntimeError(
            "Nenhuma tabela encontrada na página do IBGE. "
            "O layout do site pode ter mudado."
        )

    result: dict[str, dict[str, str]] = {}
    total = 0

    for table in tables:
        thead = table.find("thead")
        if not thead:
            continue

        # O id do thead é a sigla do estado (ex: "RJ", "SP")
        uf = thead.get("id", "").upper()
        if not uf or len(uf) != 2:
            continue

        result[uf] = {}
        rows = table.find_all("tr", class_="municipio")

        for row in rows:
            # Nome do município: dentro de <a> na primeira <td>
            link = row.find("a")
            # Código: dentro de <td class="numero">
            code_td = row.find("td", class_="numero")

            if not link or not code_td:
                continue

            city_name = link.get_text(strip=True)
            ibge_code = code_td.get_text(strip=True)

            if city_name and ibge_code:
                key = normalize(city_name)
                result[uf][key] = ibge_code
                total += 1

    print(f"  {len(result)} estados encontrados, {total} municípios no total.")
    return result


def main():
    force = "--force" in sys.argv

    if OUTPUT_FILE.exists() and not force:
        print(f"Cache já existe em {OUTPUT_FILE}. Use --force para recriar.")
        with open(OUTPUT_FILE, encoding="utf-8") as f:
            data = json.load(f)
        total = sum(len(v) for v in data.values())
        print(f"  {len(data)} estados, {total} municípios em cache.")
        return

    data = scrape_ibge()

    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print(f"Salvo em: {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
