import argparse
import subprocess
import os
import sys

def main():
    """
    Rodar todos os scripts do diretório src/testclasses/scripts para criar os includes de testes.
    """
    parser = argparse.ArgumentParser(description='NFSe Test Class Builder')
    parser.add_argument('--step', type=int, choices=[1, 2, 3], help='Rodar um único passo em específico (1, 2 ou 3).')
    parser.add_argument('--only', type=str, help='Rodar o código para apenas uma única classe/código de município.')
    parser.add_argument('--overwrite', action='store_true', help='Sobrescrever arquivos de teste existentes.')
    args = parser.parse_args()

    # Scripts na ordem correta
    scripts = [
        ('1_create.py', 1),
        ('2_mount.py', 2),
        ('3_generate.py', 3)
    ]

    base_path = os.path.dirname(os.path.abspath(__file__))
    scripts_path = os.path.join(base_path, 'scripts')

    for script_name, step_num in scripts:
        if args.step and args.step != step_num:
            continue
        
        print(f"\n--- Iniciando Passo {step_num}: {script_name} ---")
        script_full_path = os.path.join(scripts_path, script_name)
        
        if not os.path.exists(script_full_path):
            print(f"Erro: Script {script_full_path} não encontrado.")
            continue

        cmd = [sys.executable, script_full_path]
        if args.only:
            cmd.extend(['--only', args.only])
        if args.overwrite:
            cmd.append('--overwrite')
            
        try:
            result = subprocess.run(cmd, check=True)
            if result.returncode == 0:
                print(f"Passo {step_num} concluído com sucesso.")
        except subprocess.CalledProcessError as e:
            print(f"Erro ao executar o Passo {step_num}: {e}")
            sys.exit(1)

if __name__ == '__main__':
    main()
