Você receberá um ou mais arquivos PDF contendo documentos de Especificação Funcional ou Especificação Funcional-Técnica (EF/EFT).

Sua tarefa é transformar cada PDF em um documento de texto completo.

Regras obrigatórias:

1. Extraia TODO o conteúdo do documento.
2. Não omita nenhuma informação.
3. Transcreva também todo o conteúdo presente em imagens (tabelas, diagramas, prints de tela, etc).
4. Caso exista texto dentro de imagens, ele deve ser convertido para texto normal.
5. Indique sempre quando havia uma imagem no documento utilizando o formato:

[IMAGEM – descrição da imagem]

6. Após indicar a imagem, transcreva completamente todo o conteúdo textual presente nela.

7. Preserve a estrutura do documento:

   * Separar por páginas
   * Manter títulos
   * Manter tabelas
   * Manter listas
   * Manter códigos e campos técnicos

8. Quando houver tabelas:

   * Converta as tabelas para texto estruturado.
   * Preserve os nomes das colunas e os valores.

9. Para cada PDF entregue o resultado em uma seção separada no seguinte formato:

# TXT — NOME DO DOCUMENTO

```txt
CONTEÚDO COMPLETO DO DOCUMENTO
```

10. Dentro do texto indique as páginas:

PÁGINA 1
PÁGINA 2
PÁGINA 3

11. Não faça resumo.
12. Não interprete o conteúdo.
13. Não adicione nenhum comentário ou informação adicional.
14. Apenas transcreva fielmente tudo que está presente no documento.

Objetivo final:
Gerar uma transcrição textual completa do PDF que permita recriar o documento original apenas a partir do texto.

---

ETAPA ADICIONAL — GERAÇÃO DE JSON ESTRUTURADO

Após a transcrição completa do documento, gere também uma estrutura JSON contendo os principais dados técnicos identificados no documento.

Regras para o JSON:

1. O JSON deve conter apenas informações realmente presentes no documento.
2. Caso algum campo não exista no documento, retornar null.
3. Preserve exatamente a grafia dos nomes técnicos encontrados.
4. Não invente dados.
5. Não explique o JSON.

Formato da saída JSON:

# JSON — NOME DO DOCUMENTO

```json
{
  "tipo_documento": "EFT",
  "cliente": "",
  "projeto": "",
  "municipio": "",
  "estado": "",
  "titulo_programa": "",
  "versao_documento": "",
  "data_documento": "",
  "abrasf_versao": "",
  "transacoes_sap": [],
  "tabelas_sap": [],
  "classes_tecnicas": [],
  "campos_xml": [],
  "regras_negocio": [],
  "regras_tecnicas": [],
  "regras_cancelamento": [],
  "regras_competencia": [],
  "formatos_dados": []
}
```
