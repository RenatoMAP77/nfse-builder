# Automação — Classes Municipais NFS-e

Pipeline completo para criação automática de classes ABAP municipais do pacote `/S4TAX/NFSE`, partindo das especificações funcionais (EFTs) até os arquivos `.clas.abap` prontos para uso.

---

## Como funciona

```
EFTs_municipios/*.docx
       │
       ▼ (Etapa 2 — OCR via GPT-4o Vision)
EFTs_text/*.txt
       │
       ├──── IBGE (Etapa 1 — scraping ibge.gov.br) ────► ibge_codes.json
       │
       ▼ (Etapa 3 — geração via Claude API)
municipios_novos/#s4tax#nfse_{uf}{ibge}.clas.abap
       │
       ▼ (Etapa 4 — opcional, deploy direto ao SAP via ADT)
/S4TAX/NFSE no SAP
```

### Etapa 1 — Scraping IBGE
Acessa `https://www.ibge.gov.br/explica/codigos-dos-municipios.php` e salva todos os códigos IBGE em `ibge_codes.json`. Executado apenas uma vez (resultado fica em cache).

### Etapa 2 — Conversão DOCX → TXT
Lê cada `.docx` de `EFTs_municipios/` e extrai o texto. As imagens dentro do documento (tabelas de campos, regras de formato) são transcritas automaticamente pelo **GPT-4o Vision** da OpenAI e inseridas no texto como tabelas ASCII. O resultado vai para `EFTs_text/`.

### Etapa 3 — Geração das classes ABAP
Para cada `.txt` em `EFTs_text/`:
- Extrai o nome do município e a UF do nome do arquivo
- Busca o código IBGE no cache (com fallback de match fuzzy)
- Chama o **Claude API** com a especificação EFT + exemplos de classes existentes
- Gera o arquivo `.clas.abap` seguindo os padrões do `nfse-municipios.md`
- Salva em `municipios_novos/`

### Etapa 4 — Deploy SAP (opcional)
Envia os arquivos gerados diretamente ao SAP via API REST do ADT: cria a classe, envia o fonte e ativa.

---

## Pré-requisitos

**Python 3.11+** com as dependências instaladas:

```bash
pip install -r automation/requirements.txt
```

**Chaves de API necessárias:**

| Chave | Para quê | Onde obter |
|---|---|---|
| `OPENAI_API_KEY` | OCR de imagens nos .docx (Etapa 2) | https://platform.openai.com/api-keys |
| `ANTHROPIC_API_KEY` | Geração das classes ABAP (Etapa 3) | https://console.anthropic.com/ |

---

## Configuração das chaves de API

Existem três formas, use a que preferir:

### Opção A — Arquivo `.env` (recomendado)

```bash
# Copie o template e preencha com suas chaves
cp automation/.env.example automation/.env
```

Edite `automation/.env`:
```
ANTHROPIC_API_KEY=sk-ant-SuaChaveAqui
OPENAI_API_KEY=sk-SuaChaveAqui
```

> O arquivo `.env` já está no `.gitignore` e **nunca será commitado**.

### Opção B — Setup interativo

```bash
python automation/_env.py
```

O script pergunta cada chave no terminal e oferece salvar no `.env`.

### Opção C — Variável de ambiente do sistema

```powershell
# PowerShell
$env:ANTHROPIC_API_KEY = "sk-ant-..."
$env:OPENAI_API_KEY    = "sk-..."
```

```bash
# Bash / macOS
export ANTHROPIC_API_KEY="sk-ant-..."
export OPENAI_API_KEY="sk-..."
```

Quando há variável do sistema, o script usa sem perguntar. Quando há `.env`, pergunta se quer usar ou digitar uma nova.

---

## Como usar

> Todos os comandos rodam a partir da raiz do projeto (`claude_abap/`).

### Primeira execução (pipeline completo)

```bash
python automation/run_municipios.py
```

### Execuções seguintes (IBGE já em cache)

```bash
python automation/run_municipios.py --skip-ibge
```

### Processar apenas um município

```bash
python automation/run_municipios.py --skip-ibge --only "Caçador SC"
```

### Forçar regeneração de arquivos que já existem

```bash
python automation/run_municipios.py --skip-ibge --force
```

### Simular sem executar nada

```bash
python automation/run_municipios.py --dry-run
```

### Pipeline completo + deploy direto ao SAP

```bash
python automation/run_municipios.py --skip-ibge --deploy --transport SRTK123456 --yes
```

---

## Opções do orquestrador (`run_municipios.py`)

| Flag | Descrição |
|---|---|
| `--skip-ibge` | Pula o scraping do IBGE (usa `ibge_codes.json` existente) |
| `--skip-convert` | Pula a conversão DOCX→TXT (usa `EFTs_text/` existente) |
| `--only "Cidade UF"` | Processa apenas esse município |
| `--force` | Reprocessa mesmo que o arquivo de saída já exista |
| `--dry-run` | Exibe o que seria feito, sem executar |
| `--deploy` | Executa também o deploy para SAP (Etapa 4) |
| `--transport XXXX` | Número do transporte SAP para o deploy (padrão: `$TMP`) |
| `--yes` | Pula confirmações interativas no deploy |

---

## Deploy manual ao SAP (Etapa 4 separada)

Após revisar os arquivos em `municipios_novos/`, faça o deploy:

```bash
# Todos os municípios gerados
python automation/4_deploy_to_sap.py

# Apenas um município específico
python automation/4_deploy_to_sap.py --only sc4202305

# Sem confirmação interativa, com transporte específico
python automation/4_deploy_to_sap.py --transport SRTK123456 --yes
```

O script lê as credenciais SAP do `.mcp.json` (ou das variáveis de ambiente `SAP_URL`, `SAP_USER`, `SAP_PASSWORD`, `SAP_CLIENT`).

---

## Estrutura de pastas

```
claude_abap/
├── EFTs_municipios/          # INPUT: arquivos .docx com as EFTs
├── EFTs_text/                # GERADO: .txt extraídos dos .docx
├── municipios_novos/         # GERADO: .clas.abap prontos para uso
├── nfse-municipios.md        # Arquitetura e padrões das classes municipais
├── CLAUDE.md                 # Convenções gerais do projeto ABAP
└── automation/
    ├── run_municipios.py     # Orquestrador principal (ponto de entrada)
    ├── 1_scrape_ibge.py      # Etapa 1: scraping IBGE
    ├── 2_convert_efts.py     # Etapa 2: DOCX → TXT com OCR
    ├── 3_generate_classes.py # Etapa 3: geração ABAP via Claude
    ├── 4_deploy_to_sap.py    # Etapa 4: deploy ao SAP via ADT
    ├── _env.py               # Gerenciador de chaves de API
    ├── ibge_codes.json       # Cache IBGE (gerado, não commitado)
    ├── .env                  # Suas chaves (NÃO commitar — está no .gitignore)
    ├── .env.example          # Template de chaves (commitar este)
    ├── .gitignore
    └── requirements.txt
```

---

## Nomes dos arquivos EFT

O pipeline extrai o município e a UF automaticamente do nome do arquivo. O padrão esperado é:

```
COGNA_EFT - NFSe {Cidade} - {UF}.docx
```

Exemplos:
- `COGNA_EFT - NFSe Caçador - SC.docx` → classe `/s4tax/nfse_sc4202305`
- `COGNA_EFT - NFSe Ituiutaba - MG.docx` → classe `/s4tax/nfse_mg3170107`

Se o código IBGE não for encontrado por match exato, o script tenta match fuzzy e avisa. Caso não encontre, reporte o município no log e adicione manualmente ao `ibge_codes.json`.

---

## Revisão dos arquivos gerados

Antes de fazer deploy em produção, revise os arquivos em `municipios_novos/`:

- Arquivos `.clas.abap` válidos → prontos para deploy ou cópia ao repositório
- Arquivos `.clas.abap.invalid` → falharam na validação mínima, revisar manualmente

Para importar via abapGit ao invés do deploy via ADT, copie os `.clas.abap` para:
```
repositorios/orbitspot-s4tax_nfse-.../src/
```
