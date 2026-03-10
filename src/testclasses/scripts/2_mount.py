import os
import re
import argparse
from pathlib import Path

def parse_redefined_methods(file_content):
    """
    Extrai todos os métodos públicos que possuem a palavra-chave REDEFINITION
    Limpa nomes de interface (ex: /s4tax/infse_data~get_reasons_cancellation -> get_reasons_cancellation)
    """
    public_section_match = re.search(r'PUBLIC SECTION\.(.*?)(PROTECTED SECTION|PRIVATE SECTION|ENDCLASS)', file_content, re.DOTALL | re.IGNORECASE)
    if not public_section_match:
        return []
    
    public_section = public_section_match.group(1)
    # Regex para capturar o nome do método antes de REDEFINITION, lidando com interfaces ~
    raw_methods = re.findall(r'([\w/]+~?\w+)\s+REDEFINITION', public_section, re.IGNORECASE)
    
    clean_methods = []
    for m in raw_methods:
        # Se tiver ~, pega só a parte depois do ~
        clean_name = m.split('~')[-1]
        if clean_name not in clean_methods:
            clean_methods.append(clean_name)
            
    return clean_methods

def mount_test_class(filename_base, class_name, methods):
    """
    Gera a estrutura de testes simplificada (apenas ltcl_)
    """
    test_class_name = f"ltcl_{class_name.split('/')[-1].lower()}"
    
    # Adicionar métodos padrão se não existirem
    methods_to_test = methods.copy()
    
    methods_def = "\n      ".join([f"{m} FOR TESTING RAISING cx_static_check," for m in methods_to_test])
    if methods_def.endswith(','):
        methods_def = methods_def[:-1] + "."

    definition = f"""*&---------------------------------------------------------------------*
*& Include {filename_base}
*&---------------------------------------------------------------------*
CLASS {test_class_name} DEFINITION FINAL FOR TESTING
  INHERITING FROM /s4tax/nfse_default_test
    DURATION SHORT
    RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA: cut TYPE REF TO {class_name}.
    CLASS-DATA: cached_class_name TYPE seoclname.
    CLASS-METHODS: class_setup.

    METHODS:
      setup,
      {methods_def}
ENDCLASS.

CLASS {test_class_name} IMPLEMENTATION.
  
  METHOD class_setup.
    DATA: cut TYPE REF TO {class_name}.
    cached_class_name = /s4tax/tests_utils=>get_classname_by_data( cut ).
  ENDMETHOD.
  
  METHOD setup.
    DATA: cx_root TYPE REF TO cx_root.
    TRY.
        me->branch_info->get_class( )->set_class( cached_class_name ).
        cut ?= /s4tax/nfse_default=>get_instance( branch_info = me->branch_info documents = me->documents reporter = reporter ).
      CATCH cx_root INTO cx_root.
    ENDTRY.
  ENDMETHOD.
"""
    implementation = []
    for method in methods_to_test:
        implementation.append(f"""
  METHOD {method}.
    "Vazio
  ENDMETHOD.""")
    
    return definition + "\n".join(implementation) + "\n\nENDCLASS."

def run(only_code=None, overwrite=False):
    root_dir = Path(__file__).resolve().parent.parent.parent.parent
    input_dir = root_dir / 'output' / 'nfse_classes'
    output_dir = root_dir / 'output' / 'nfse_testclasses'

    if not output_dir.exists():
        print(f"Pasta de saída não encontrada: {output_dir}")
        return

    test_files = list(output_dir.glob('*_t99.inc.abap'))
    
    count = 0
    for test_file in test_files:
        if only_code and only_code.lower() not in test_file.name.lower():
            continue
            
        # Verifica se o arquivo já está montado
        with open(test_file, 'r', encoding='utf-8') as f:
            current_content = f.read()
        
        if "DEFINITION FINAL FOR TESTING" in current_content and not overwrite:
            print(f"Arquivo já montado, pulando: {test_file.name}")
            continue

        original_file_name = test_file.name.replace('_t99.inc.abap', '.clas.abap')
        original_path = input_dir / original_file_name
        
        if not original_path.exists():
            continue

        with open(original_path, 'r', encoding='utf-8') as f:
            content = f.read()

        class_match = re.search(r'CLASS\s+([\w/]+)\s+DEFINITION', content, re.IGNORECASE)
        if not class_match:
            continue
            
        class_name = class_match.group(1)
        methods = parse_redefined_methods(content)
        
        test_content = mount_test_class(test_file.stem, class_name, methods)
        
        with open(test_file, 'w', encoding='utf-8') as f:
            f.write(test_content)
        
        count += 1

    print(f"Passo 2 concluído: {count} arquivos montados em {output_dir}")

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Passo 2: Montar estrutura de testes.')
    parser.add_argument('--only', type=str, help='Código da NFSe específico (ex: mg3106200)')
    parser.add_argument('--overwrite', action='store_true', help='Sobrescrever arquivos de teste existentes.')
    args = parser.parse_args()
    
    run(only_code=args.only, overwrite=args.overwrite)
