import os
import shutil
import argparse
from pathlib import Path

def run(only_code=None, overwrite=False):
    # Identifica a raiz do projeto (3 níveis acima de src/testclasses/scripts/)
    root_dir = Path(__file__).resolve().parent.parent.parent.parent
    input_dir = root_dir / 'output' / 'nfse_classes'
    output_dir = root_dir / 'output' / 'nfse_testclasses'

    if not output_dir.exists():
        output_dir.mkdir(parents=True)

    print(f"Lendo classes de: {input_dir}")
    
    if not input_dir.exists():
        print(f"Erro: Diretório de entrada não encontrado: {input_dir}")
        return

    files = list(input_dir.glob('*.clas.abap'))
    if not files:
        print(f"Nenhuma classe encontrada em {input_dir}")
        return

    count = 0
    for file_path in files:
        # Se 'only_code' for fornecido, filtrar pelo código do município
        if only_code and only_code.lower() not in file_path.name.lower():
            continue

        new_name = file_path.name.replace('.clas.abap', '_t99.inc.abap')
        destination = output_dir / new_name
        
        # Se não houver overwrite, pula se o arquivo de destino já existir
        if destination.exists() and not overwrite:
            print(f"Arquivo já existe, pulando: {destination.name}")
            continue

        shutil.copy(file_path, destination)
        count += 1

    print(f"Passo 1 concluído: {count} arquivos criados em {output_dir}")

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Passo 1: Criar arquivos de teste.')
    parser.add_argument('--only', type=str, help='Código da NFSe específico (ex: mg3106200)')
    parser.add_argument('--overwrite', action='store_true', help='Sobrescrever arquivos de teste existentes.')
    args = parser.parse_args()
    
    run(only_code=args.only, overwrite=args.overwrite)
