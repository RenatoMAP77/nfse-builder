# Automação — Classes Municipais NFS-e

Pipeline para criação automática de classes ABAP municipais do pacote `/S4TAX/NFSE`, partindo das especificações funcionais (EFTs) até os arquivos `.clas.abap` prontos para uso.

**Toda geração de IA usa o `claude` CLI local — zero API keys necessárias.**

---

## Como funciona

```
EFTs Novas PDF/*.pdf  ──┐
EFTs Novas/*.docx     ──┤ (Etapa 2 — transcrição via claude CLI)
                        │
                        ▼
                  EFTs txt/*.txt
                        │
         ibge_codes.json (Etapa 1 — scraping ibge.gov.br)
                        │
                        ▼ (Etapa 3 — geração ABAP via claude CLI)
          Municipios Prontos/#s4tax#nfse_{uf}{ibge}.clas.abap
                        │
                        ▼ (Etapa 4 — opcional, deploy direto ao SAP via ADT)
                  /S4TAX/NFSE no SAP
```

### Etapa 1 — Scraping IBGE
Acessa `https://www.ibge.gov.br/explica/codigos-dos-municipios.php` e salva todos os códigos IBGE em `ibge_codes.json`. Executado apenas uma vez (resultado fica em cache).

### Etapa 2 — Conversão EFT → TXT
Lê arquivos de `EFTs Novas PDF/` (`.pdf`, preferencial) e `EFTs Novas/` (`.docx`, fallback). Extrai texto e transcreve imagens (tabelas de campos, regras de formato) via **claude CLI**. O resultado vai para `EFTs txt/`.

> Se os `.txt` já existem em `EFTs txt/`, use `--use-existing-efts` para pular esta etapa.

### Etapa 3 — Geração das classes ABAP
Para cada `.txt` em `EFTs txt/`:
- Extrai nome do município e UF do nome do arquivo
- Busca o código IBGE no cache (com fallback de match fuzzy)
- Chama o **claude CLI** com a EFT + arquitetura (`nfse-municipios.md`) + exemplos de classes existentes
- Gera o arquivo `.clas.abap` seguindo os padrões do projeto
- Salva em `Municipios Prontos/`
- Atualiza automaticamente a tabela em `Municipios Prontos/lista_prontos.md`

### Etapa 4 — Deploy SAP (opcional)
Envia os arquivos gerados diretamente ao SAP via API REST do ADT.

---

## Pré-requisito único

**`claude` CLI instalado e autenticado:**

```bash
npm install -g @anthropic-ai/claude-code
claude login
```

Verificar se está funcionando:
```bash
claude --version
```

**Python 3.11+** com as dependências:
```bash
pip install -r requirements.txt
```

---

## Como usar — via Claude Code

Todos os comandos são executados pedindo ao Claude Code para rodar:

### Usar EFTs txt já prontos e gerar todas as classes

```
execute: python run_municipios.py --skip-ibge --use-existing-efts
```

### Processar apenas um município

```
execute: python run_municipios.py --skip-ibge --use-existing-efts --only "Toledo PR"
```

### Pipeline completo (com conversão de novos PDFs/DOCXs)

```
execute: python run_municipios.py --skip-ibge
```

### Forçar regeneração de classes já existentes

```
execute: python run_municipios.py --skip-ibge --use-existing-efts --force
```

### Simular sem executar nada

```
execute: python run_municipios.py --dry-run
```

### Pipeline completo + deploy direto ao SAP

```
execute: python run_municipios.py --skip-ibge --use-existing-efts --deploy --transport SRTK123456 --yes
```

---

## Opções do orquestrador (`run_municipios.py`)

| Flag | Descrição |
|---|---|
| `--skip-ibge` | Pula o scraping do IBGE (usa `ibge_codes.json` existente) |
| `--skip-convert` | Pula a conversão e usa `EFTs txt/` existente |
| `--use-existing-efts` | Igual ao anterior — usa `EFTs txt/` pré-convertidos |
| `--only "Cidade UF"` | Processa apenas esse município (ex: `"Toledo PR"`) |
| `--force` | Reprocessa mesmo que o arquivo de saída já exista |
| `--dry-run` | Exibe o que seria feito, sem executar |
| `--deploy` | Executa também o deploy para SAP (Etapa 4) |
| `--transport XXXX` | Número do transporte SAP para o deploy (padrão: `$TMP`) |
| `--yes` | Pula confirmações interativas no deploy |

---

## Estrutura de pastas

```
nfse-builder/
├── run_municipios.py         # Orquestrador principal (ponto de entrada)
├── 1_scrape_ibge.py          # Etapa 1: scraping IBGE
├── 2_convert_efts.py         # Etapa 2: PDF/DOCX → TXT com transcrição de imagens
├── 3_generate_classes.py     # Etapa 3: geração ABAP via claude CLI
├── 4_deploy_to_sap.py        # Etapa 4: deploy ao SAP via ADT
├── _env.py                   # Gerenciador de credenciais SAP (para deploy)
├── ibge_codes.json           # Cache IBGE (gerado automaticamente)
├── requirements.txt          # Dependências Python
├── .env                      # Credenciais SAP (NÃO commitar)
├── .env.example              # Template de credenciais
│
├── EFTs Novas/               # INPUT: arquivos .docx com as EFTs
├── EFTs Novas PDF/           # INPUT: arquivos .pdf com as EFTs (preferencial)
├── EFTs txt/                 # EFTs já convertidas para .txt (input da Etapa 3)
│
└── Municipios Prontos/       # OUTPUT: .clas.abap gerados
    └── lista_prontos.md      # Tabela de municípios já processados
```

Os arquivos de referência (`nfse-municipios.md`, `CLAUDE.md`, `repositorios/`) ficam na pasta pai `claude_abap/` e são carregados automaticamente pelo pipeline.

---

## Nomes dos arquivos EFT

O pipeline extrai o município e a UF automaticamente do nome do arquivo. Padrão esperado:

```
COGNA_EFT - NFSe {Cidade} - {UF}.pdf
COGNA_EFT - NFSe {Cidade} - {UF}.docx
```

Exemplos:
- `COGNA_EFT - NFSe Toledo - PR.pdf` → classe `/s4tax/nfse_pr4127700`
- `COGNA_EFT - NFSe Caçador - SC.docx` → classe `/s4tax/nfse_sc4202305`

Se o código IBGE não for encontrado por match exato, o script tenta match fuzzy e avisa no log.

---

## Revisão dos arquivos gerados

Após a Etapa 3, verifique em `Municipios Prontos/`:

- `.clas.abap` → válidos, prontos para deploy ou cópia ao repositório
- `.clas.abap.invalid` → falharam na validação mínima, revisar manualmente

Para importar via abapGit ao invés do deploy via ADT, copie os `.clas.abap` para:
```
repositorios/orbitspot-s4tax_nfse-.../src/
```

---

## Deploy manual ao SAP (Etapa 4 separada)

```bash
# Todos os municípios em "Municipios Prontos/"
python 4_deploy_to_sap.py

# Apenas um município específico
python 4_deploy_to_sap.py --only pr4127700

# Sem confirmação interativa, com transporte específico
python 4_deploy_to_sap.py --transport SRTK123456 --yes
```

O script lê as credenciais SAP do `.env` (ou das variáveis de ambiente `SAP_URL`, `SAP_USER`, `SAP_PASSWORD`, `SAP_CLIENT`).
