import os
import re
import argparse
import subprocess
from pathlib import Path

def check_gemini_cli():
    try:
        # Verifica se o npx está disponível
        result = subprocess.run(['npx', '--version'], capture_output=True, text=True, shell=True)
        return result.returncode == 0
    except Exception:
        return False

def get_examples(root_dir):
    examples_dir = root_dir / 'src' / 'testclasses' / 'files' / 'testclasses_examples'
    examples_text = "Exemplos de referência (Classe -> Teste):\n\n"
    if not examples_dir.exists(): return ""
    pairs = {}
    for file in examples_dir.glob('*.abap'):
        match = re.search(r'nfse_(\w+)', file.name)
        if match:
            code = match.group(1)
            if code not in pairs: pairs[code] = {'class': None, 'test': None}
            if '.clas.abap' in file.name: pairs[code]['class'] = file
            elif '_t99.inc.abap' in file.name: pairs[code]['test'] = file

    for code, files in pairs.items():
        if files['class'] and files['test']:
            try:
                with open(files['class'], 'r', encoding='utf-8') as f: c = f.read()
                with open(files['test'], 'r', encoding='utf-8') as f: t = f.read()
                examples_text += f"Município {code}:\nCLASSE:\n{c}\nTESTE:\n{t}\n---\n"
            except Exception: continue
    return examples_text

def call_gemini_cli(prompt):
    """
    Chama o Gemini CLI passando o prompt via stdin para evitar erros de limite de comando.
    """
    try:
        # No Windows, usamos shell=True para encontrar o npx no PATH
        # Passamos o prompt via 'input' para o stdin
        result = subprocess.run(
            ['npx', '@google/gemini-cli'], 
            input=prompt,
            capture_output=True, 
            text=True, 
            encoding='utf-8', 
            shell=True, 
            check=True
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f"  [!] Erro Gemini (Status {e.returncode}): {e.stderr}")
        return None
    except Exception as e:
        print(f"  [!] Erro inesperado ao chamar Gemini: {e}")
        return None

def run(only_code=None, overwrite=False):
    root_dir = Path(__file__).resolve().parent.parent.parent.parent
    test_dir = root_dir / 'output' / 'nfse_testclasses'
    input_dir = root_dir / 'output' / 'nfse_classes'
    
    if not check_gemini_cli():
        print("  [!] Erro: 'npx' não encontrado no sistema.")
        return

    examples = get_examples(root_dir)
    test_files = list(test_dir.glob('*_t99.inc.abap'))
    
    for test_file in test_files:
        if only_code and only_code.lower() not in test_file.name.lower(): continue
            
        print(f"Processando: {test_file.name}")
        try:
            with open(test_file, 'r', encoding='utf-8') as f: test_content = f.read()
            original_file = input_dir / test_file.name.replace('_t99.inc.abap', '.clas.abap')
            if not original_file.exists(): continue
            with open(original_file, 'r', encoding='utf-8') as f: original_content = f.read()
        except Exception as e:
            print(f"  [!] Erro ao ler arquivos: {e}")
            continue

        method_blocks = re.findall(r'METHOD (\w+)\.(.*?)ENDMETHOD\.', test_content, re.DOTALL | re.IGNORECASE)
        methods_to_generate = []
        for name, body in method_blocks:
            if name.lower() in ['setup', 'class_setup']: continue
            if re.search(r'^\s*"?Vazio"?\s*$', body.strip(), re.IGNORECASE) or body.strip() == "" or overwrite:
                methods_to_generate.append(name)

        if not methods_to_generate:
            print("  Nenhum método para gerar.")
            continue

        print(f"  -> Gerando {len(methods_to_generate)} métodos via IA...")
        
        prompt = f"""Você é um expert em ABAP Unit. Gere o código interno para os métodos da classe abaixo.
BREVIDADE MÁXIMA: Cada método deve ter no máximo 5-8 linhas.

--- CLASSE ---
{original_content}

--- EXEMPLOS ---
{examples}

--- MÉTODOS PARA IMPLEMENTAR ---
{', '.join(methods_to_generate)}

--- FORMATO DE RESPOSTA (OBRIGATÓRIO) ---
Para cada método, retorne exatamente assim:
@@@METHOD_START:[nome_do_metodo]
[codigo_abap_unit]
@@@METHOD_END

NÃO inclua explicações ou blocos markdown, apenas os delimitadores e o código.
"""
        ai_response = call_gemini_cli(prompt)
        if not ai_response: 
            print("  [!] Sem resposta da IA.")
            continue

        new_test_content = test_content
        for method_name in methods_to_generate:
            pattern_ai = rf'@@@METHOD_START:{method_name}\s*(.*?)\s*@@@METHOD_END'
            match_ai = re.search(pattern_ai, ai_response, re.DOTALL | re.IGNORECASE)
            
            if match_ai:
                logic = match_ai.group(1).strip()
                logic = re.sub(r'```[a-z]*\n?', '', logic).replace('```', '')
                
                pattern_replace = rf'(METHOD {method_name}\.)(.*?)(ENDMETHOD\.)'
                logic_escaped = logic.replace('\\', '\\\\').replace('$', '\\$')
                new_test_content = re.sub(pattern_replace, rf'\1\n    {logic_escaped}\n  \3', new_test_content, flags=re.DOTALL | re.IGNORECASE)
                print(f"    [OK] {method_name}")
            else:
                print(f"    [!] Lógica não encontrada para {method_name}")

        with open(test_file, 'w', encoding='utf-8') as f:
            f.write(new_test_content)

    print("\nConcluído.")

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--only', type=str)
    parser.add_argument('--overwrite', action='store_true')
    args = parser.parse_args()
    run(only_code=args.only, overwrite=args.overwrite)
