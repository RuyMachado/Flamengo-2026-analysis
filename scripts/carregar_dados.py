"""
Script de upsert dos dados do projeto Flamengo 2026 Analysis.

O que ele faz:
  1. Le cada CSV em data/raw/
  2. Conecta no PostgreSQL usando as credenciais do .env
  3. Insere linhas novas e atualiza linhas ja existentes (upsert), respeitando a ordem de dependencia das Foreign Keys

Tabelas com upsert (que tem UNIQUE constraint no banco):
  - jogadores                          (chave: nome)
  - estatisticas_time_competicao       (chave: time_id + competicao_id)
  - estatisticas_jogador_competicao    (chave: jogador_id + competicao_id)

Tabelas sem upsert (ainda nao tem UNIQUE constraint) -> so fazem INSERT.
Rodar o script duas vezes com o mesmo CSV nessas tabelas gera duplicata:
  - treinadores
  - times
  - competicoes
  - contratos_jogador

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


def inserir_simples(df, tabela):
    """
    INSERT simples, sem upsert.
    Usar so em tabelas sem UNIQUE constraint (treinadores, times,
    competicoes, contratos_jogador). Rodar duas vezes duplica dados.
    """
    df.to_sql(tabela, engine, if_exists="append", index=False)
    print(f"[{tabela}] {len(df)} linha(s) inserida(s) (insert simples).")


def upsert(df, tabela, colunas_conflito):
    """
    INSERT ON CONFLICT DO UPDATE
    Usar em tabelas que JA TEM UNIQUE constraint no banco:
      - jogadores                        -> colunas_conflito=["nome"]
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
    # 1) treinadores -> sem dependencia
    df = ler_csv("treinadores.csv")
    inserir_simples(df, "treinadores")

    # 2) times -> depende de treinadores (treinador_id)
    df = ler_csv("times.csv")
    inserir_simples(df, "times")

    # 3) competicoes -> sem dependencia
    df = ler_csv("competicoes.csv")
    inserir_simples(df, "competicoes")

    # 4) jogadores -> sem dependencia, TEM unique constraint (nome)
    df = ler_csv("jogadores.csv")
    upsert(df, "jogadores", colunas_conflito=["nome"])

    # 5) contratos_jogador -> depende de jogadores (jogador_id)
    #    ATENCAO: jogador_id no CSV precisa ser o id real gerado pelo banco.
    #    Consulte antes: SELECT id, nome FROM jogadores ORDER BY id;
    csv_contratos = DATA_DIR / "contratos_jogador.csv"
    if csv_contratos.exists():
        df = ler_csv("contratos_jogador.csv")
        inserir_simples(df, "contratos_jogador")
    else:
        print("[contratos_jogador] CSV ainda nao existe, pulando.")

    # 6) estatisticas_time_competicao -> depende de times + competicoes
    csv_est_time = DATA_DIR / "estatisticas_time_competicao.csv"
    if csv_est_time.exists():
        df = ler_csv("estatisticas_time_competicao.csv")
        upsert(df, "estatisticas_time_competicao",
               colunas_conflito=["time_id", "competicao_id"])
    else:
        print("[estatisticas_time_competicao] CSV ainda nao existe, pulando.")

    # 7) estatisticas_jogador_competicao -> depende de jogadores + competicoes
    csv_est_jogador = DATA_DIR / "estatisticas_jogador_competicao.csv"
    if csv_est_jogador.exists():
        df = ler_csv("estatisticas_jogador_competicao.csv")
        upsert(df, "estatisticas_jogador_competicao",
               colunas_conflito=["jogador_id", "competicao_id"])
    else:
        print("[estatisticas_jogador_competicao] CSV ainda nao existe, pulando.")

    print("\nCarregamento finalizado.")


if __name__ == "__main__":
    main()