"""
Script de upsert dos dados do projeto Flamengo 2026 Analysis.

O que ele faz:
  1. Le cada CSV em data/raw/
  2. Conecta no PostgreSQL usando as credenciais do .env
  3. Insere linhas novas e atualiza linhas ja existentes (upsert), respeitando a ordem de dependencia das Foreign Keys

Todas as tabelas usam upsert (todas tem UNIQUE constraint no banco):
  - treinadores                        (chave: nome)
  - times                              (chave: nome)
  - competicoes                        (chave: nome + temporada)
  - jogadores                          (chave: nome)
  - contratos_jogador                  (chave: jogador_id + data_contratacao)
  - estatisticas_time_competicao       (chave: time_id + competicao_id)
  - estatisticas_jogador_competicao    (chave: jogador_id + competicao_id)

O script pode ser rodado quantas vezes for necessario, mesmo repetindo
linhas ja inseridas antes -> nunca duplica, so atualiza.

Como rodar:
  python carregar_dados.py
"""

import os
from pathlib import Path

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine, text

# ---------------------------------------------------------------------------
# 1. Configuracao
# ---------------------------------------------------------------------------

load_dotenv()  # le o arquivo .env na raiz do projeto

DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT")
DB_NAME = os.getenv("DB_NAME")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")

DATA_DIR = Path(__file__).resolve().parent.parent / "data" / "raw"

engine = create_engine(
    f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
)


# ---------------------------------------------------------------------------
# 2. Funcoes auxiliares
# ---------------------------------------------------------------------------

def ler_csv(nome_arquivo):
    """Le um CSV de data/raw/, tratando encoding e valores vazios como NULL."""
    caminho = DATA_DIR / nome_arquivo
    df = pd.read_csv(caminho, encoding="utf-8-sig")
    # troca string vazia por None -> vira NULL no banco
    df = df.where(pd.notnull(df), None)
    return df


def upsert(df, tabela, colunas_conflito):
    """
    INSERT ON CONFLICT DO UPDATE
    Usar em tabelas que JA TEM UNIQUE constraint no banco:
      - treinadores                      -> colunas_conflito=["nome"]
      - times                            -> colunas_conflito=["nome"]
      - competicoes                      -> colunas_conflito=["nome", "temporada"]
      - jogadores                        -> colunas_conflito=["nome"]
      - contratos_jogador                -> colunas_conflito=["jogador_id", "data_contratacao"]
      - estatisticas_time_competicao     -> colunas_conflito=["time_id", "competicao_id"]
      - estatisticas_jogador_competicao  -> colunas_conflito=["jogador_id", "competicao_id"]
    """
    colunas = list(df.columns)
    colunas_update = [coluna for coluna in colunas if coluna not in colunas_conflito]

    placeholders = ", ".join(f":{coluna}" for coluna in colunas)
    colunas_sql = ", ".join(colunas)
    conflito_sql = ", ".join(colunas_conflito)
    update_sql = ", ".join(f"{coluna} = EXCLUDED.{coluna}" for coluna in colunas_update)

    query = text(f"""
        INSERT INTO {tabela} ({colunas_sql})
        VALUES ({placeholders})
        ON CONFLICT ({conflito_sql})
        DO UPDATE SET {update_sql}
    """)

    with engine.begin() as conn:
        for _, row in df.iterrows():
            conn.execute(query, row.to_dict())

    print(f"[{tabela}] {len(df)} linha(s) processada(s) (upsert).")


# ---------------------------------------------------------------------------
# 3. Ordem de alimentação (respeita as Foreign Keys)
# ---------------------------------------------------------------------------

def main():
    # 1) treinadores -> sem dependencia, TEM unique constraint (nome)
    df = ler_csv("treinadores.csv")
    upsert(df, "treinadores", colunas_conflito=["nome"])

    # 2) times -> depende de treinadores (treinador_id), TEM unique constraint (nome)
    df = ler_csv("times.csv")
    upsert(df, "times", colunas_conflito=["nome"])

    # 3) competicoes -> sem dependencia, TEM unique constraint (nome + temporada)
    df = ler_csv("competicoes.csv")
    upsert(df, "competicoes", colunas_conflito=["nome", "temporada"])

    # 4) jogadores -> sem dependencia, TEM unique constraint (nome)
    df = ler_csv("jogadores.csv")
    upsert(df, "jogadores", colunas_conflito=["nome"])

    print("\nCarregamento finalizado.")


if __name__ == "__main__":
    main()