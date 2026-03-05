"""
2_convert_efts.py
Converte arquivos .pdf e .docx para .txt em "EFTs txt/".
Imagens são transcritas via claude CLI (sem API keys).

Pastas de entrada:
  EFTs Novas PDF/   -> arquivos .pdf  (preferencial)
  EFTs Novas/       -> arquivos .docx (fallback)

Pasta de saída:
  EFTs txt/

Uso:
  python src/scripts/2_convert_efts.py [--only "NOME_ARQUIVO"] [--force]
  --only: processa apenas o arquivo cujo nome contenha esse trecho
  --force: reprocessa mesmo se .txt já existir
"""
import os
import shutil
import subprocess
import sys
import tempfile
import unicodedata
import zipfile
from pathlib import Path

ROOT_DIR       = Path(__file__).parent.parent.parent   # nfse-builder/
INPUT_DIR_PDF  = ROOT_DIR / "EFTs Novas PDF"
INPUT_DIR_DOCX = ROOT_DIR / "EFTs Novas"
OUTPUT_DIR     = ROOT_DIR / "EFTs txt"


# ---------------------------------------------------------------------------
# Claude CLI helpers
# ---------------------------------------------------------------------------

def _clean_env() -> dict:
    """Remove CLAUDECODE para permitir chamada aninhada a partir do Claude Code."""
    env = os.environ.copy()
    env.pop("CLAUDECODE", None)
    return env


def call_claude(prompt: str, timeout: int = 120) -> str:
    """Chama o claude CLI via stdin. Sem API keys."""
    if not shutil.which("claude"):
        raise RuntimeError(
            "claude CLI não encontrado no PATH. "
            "Execute: npm install -g @anthropic-ai/claude-code"
        )
    result = subprocess.run(
        ["claude", "--print"],
        input=prompt, env=_clean_env(),
        capture_output=True, text=True, encoding="utf-8", timeout=timeout
    )
    if result.returncode != 0:
        raise RuntimeError(f"claude CLI erro: {result.stderr[:500]}")
    return result.stdout.strip()


def call_claude_with_image(prompt: str, image_path: str, timeout: int = 60) -> str:
    """Usa claude CLI para transcrever uma imagem."""
    if not shutil.which("claude"):
        raise RuntimeError(
            "claude CLI não encontrado no PATH. "
            "Execute: npm install -g @anthropic-ai/claude-code"
        )
    result = subprocess.run(
        ["claude", "--print", "-p", prompt, image_path],
        env=_clean_env(),
        capture_output=True, text=True, encoding="utf-8", timeout=timeout
    )
    if result.returncode != 0:
        raise RuntimeError(f"Erro ao transcrever imagem: {result.stderr[:300]}")
    return result.stdout.strip()


IMAGE_PROMPT = (
    "Esta imagem faz parte de uma especificação funcional (EFT) de NFS-e brasileira. "
    "Transcreva TODO o conteúdo visível para texto puro. "
    "Se for tabela, preserve colunas no formato ASCII. "
    "Se for texto ou tela de sistema, transcreva exatamente. "
    "Não adicione comentários — apenas o conteúdo."
)


# ---------------------------------------------------------------------------
# PDF conversion (pymupdf)
# ---------------------------------------------------------------------------

def convert_pdf_to_text(pdf_path: Path) -> str:
    try:
        import fitz
    except ImportError:
        raise RuntimeError(
            "pymupdf não instalado. Execute: pip install pymupdf"
        )

    doc = fitz.open(str(pdf_path))
    lines = []
    image_counter = 0

    for page_num, page in enumerate(doc):
        text = page.get_text("text")
        if text.strip():
            lines.append(f"\n--- Página {page_num + 1} ---")
            lines.append(text)

        image_list = page.get_images(full=True)
        for img_ref in image_list:
            xref = img_ref[0]
            base_image = doc.extract_image(xref)
            image_bytes = base_image["image"]
            image_ext = base_image["ext"]

            tmp_img = Path(tempfile.mktemp(suffix=f".{image_ext}"))
            tmp_img.write_bytes(image_bytes)

            image_counter += 1
            print(f"    Transcrevendo imagem {image_counter} (pag {page_num + 1})...")
            try:
                transcription = call_claude_with_image(IMAGE_PROMPT, str(tmp_img))
                lines.append(f"\n[IMAGEM {image_counter} TRANSCRITA]")
                lines.append(transcription)
                lines.append(f"[FIM IMAGEM {image_counter}]\n")
            except Exception as e:
                lines.append(f"\n[IMAGEM {image_counter} - erro: {e}]\n")
            finally:
                tmp_img.unlink(missing_ok=True)

    doc.close()
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# DOCX conversion (python-docx + zipfile)
# ---------------------------------------------------------------------------

def _get_docx_images(docx_path: Path) -> dict:
    """Extrai imagens do .docx como {relationship_id: (bytes, ext)}."""
    images = {}
    with zipfile.ZipFile(docx_path, "r") as z:
        # Carrega mapeamento rid -> arquivo de mídia
        import xml.etree.ElementTree as ET
        rels_path = "word/_rels/document.xml.rels"
        rid_to_media = {}
        if rels_path in z.namelist():
            rels_xml = z.read(rels_path)
            tree = ET.fromstring(rels_xml)
            for rel in tree:
                rid = rel.get("Id", "")
                target = rel.get("Target", "")
                if "media/" in target:
                    rid_to_media[rid] = "word/" + target.lstrip("/")

        # Carrega bytes de cada imagem
        for rid, media_path in rid_to_media.items():
            if media_path in z.namelist():
                ext = media_path.rsplit(".", 1)[-1].lower()
                images[rid] = (z.read(media_path), ext, media_path.split("/")[-1])

    return images


def convert_docx_to_text(docx_path: Path) -> str:
    try:
        from docx import Document
        from docx.oxml.ns import qn
    except ImportError:
        raise RuntimeError(
            "python-docx não instalado. Execute: pip install python-docx"
        )

    doc = Document(docx_path)
    images_data = _get_docx_images(docx_path)

    lines = []
    image_counter = 0

    for para in doc.paragraphs:
        drawings = para._element.findall(".//" + qn("w:drawing"))

        if drawings:
            for drawing in drawings:
                blips = drawing.findall(".//" + qn("a:blip"))
                for blip in blips:
                    embed = blip.get(qn("r:embed"))
                    if embed and embed in images_data:
                        img_bytes, ext, img_name = images_data[embed]
                        tmp_img = Path(tempfile.mktemp(suffix=f".{ext}"))
                        tmp_img.write_bytes(img_bytes)

                        image_counter += 1
                        print(f"    Transcrevendo imagem {image_counter}: {img_name} ...")
                        try:
                            transcription = call_claude_with_image(IMAGE_PROMPT, str(tmp_img))
                            lines.append(f"\n[IMAGEM {image_counter} TRANSCRITA - {img_name}]")
                            lines.append(transcription)
                            lines.append(f"[FIM DA IMAGEM {image_counter}]\n")
                        except Exception as e:
                            lines.append(f"\n[IMAGEM {image_counter} - erro: {e}]\n")
                        finally:
                            tmp_img.unlink(missing_ok=True)
        else:
            text = para.text
            if text.strip():
                lines.append(text)

    # Tabelas
    for table in doc.tables:
        rows_text = []
        for row in table.rows:
            cells = [cell.text.strip() for cell in row.cells]
            rows_text.append(" | ".join(cells))
        if rows_text:
            lines.append("\n" + "\n".join(rows_text) + "\n")

    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Funções de suporte
# ---------------------------------------------------------------------------

def normalize(name: str) -> str:
    nfkd = unicodedata.normalize("NFKD", name)
    return "".join(c for c in nfkd if not unicodedata.combining(c)).lower().strip()


def collect_source_files(only) -> list:
    """
    Retorna lista de (arquivo_fonte, tipo) para processar.
    Prioriza PDF quando o mesmo stem existe nos dois formatos.
    tipo = "pdf" ou "docx"
    """
    pdf_files = {}
    if INPUT_DIR_PDF.exists():
        for f in INPUT_DIR_PDF.glob("*.pdf"):
            pdf_files[normalize(f.stem)] = (f, "pdf")

    docx_files = {}
    if INPUT_DIR_DOCX.exists():
        for f in INPUT_DIR_DOCX.glob("*.docx"):
            docx_files[normalize(f.stem)] = (f, "docx")

    # Merge: PDF tem prioridade
    combined = {**docx_files, **pdf_files}

    files = list(combined.values())
    files.sort(key=lambda t: normalize(t[0].stem))

    if only:
        only_norm = normalize(only)
        files = [t for t in files if only_norm in normalize(t[0].stem)]

    return files


def process_file(src_path: Path, file_type: str, force: bool) -> bool:
    """Converte um arquivo para .txt. Retorna True se bem-sucedido."""
    out_path = OUTPUT_DIR / (src_path.stem + ".txt")

    if out_path.exists() and not force:
        print(f"  [PULAR] {src_path.name} — .txt já existe. Use --force para reprocessar.")
        return True

    print(f"  Convertendo ({file_type.upper()}): {src_path.name}")
    try:
        if file_type == "pdf":
            content = convert_pdf_to_text(src_path)
        else:
            content = convert_docx_to_text(src_path)

        OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
        out_path.write_text(content, encoding="utf-8")
        print(f"  [OK] Salvo: {out_path.name}")
        return True
    except Exception as e:
        print(f"  [ERRO] {src_path.name}: {e}")
        return False


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    print("=== Etapa 2: Conversão EFT -> TXT ===\n")
    print(f"  Entrada PDF:  {INPUT_DIR_PDF}")
    print(f"  Entrada DOCX: {INPUT_DIR_DOCX}")
    print(f"  Saida:        {OUTPUT_DIR}\n")

    force = "--force" in sys.argv
    only = None
    if "--only" in sys.argv:
        idx = sys.argv.index("--only")
        if idx + 1 < len(sys.argv):
            only = sys.argv[idx + 1]

    files = collect_source_files(only)

    if not files:
        if only:
            print(f"ERRO: Nenhum arquivo encontrado com '{only}' no nome.")
            sys.exit(1)
        print("Nenhum arquivo .pdf/.docx encontrado nas pastas de entrada.")
        sys.exit(0)

    if only:
        print(f"Filtro ativo: '{only}' -> {len(files)} arquivo(s)\n")
    else:
        print(f"Processando {len(files)} arquivo(s)...\n")

    success = 0
    errors = 0

    for src_path, file_type in files:
        ok = process_file(src_path, file_type, force)
        if ok:
            success += 1
        else:
            errors += 1

    print(f"\nConcluido: {success} convertido(s), {errors} erro(s).")
    if errors:
        sys.exit(1)


if __name__ == "__main__":
    main()
