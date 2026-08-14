-- =====================================================================
-- Schema: Flamengo 2026 Season Analysis
-- Banco: PostgreSQL 16
-- =====================================================================

-- =====================================================================
-- Tabela: competicoes
-- =====================================================================
CREATE TABLE competicoes (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    temporada SMALLINT NOT NULL,
    tipo VARCHAR(20) CHECK (tipo IN ('Nacional', 'Continental', 'Estadual', 'Copa'))
);

-- =====================================================================
-- Tabela: treinadores
-- =====================================================================
CREATE TABLE treinadores (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    nacionalidade VARCHAR(50),
    data_nascimento DATE,
    idade SMALLINT CHECK (idade > 18 AND idade < 90),
    formacao_favorita VARCHAR(20)
);

-- =====================================================================
-- Tabela: times
-- =====================================================================
CREATE TABLE times (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    pais VARCHAR(50),
    treinador_id INTEGER REFERENCES treinadores(id)
);

-- =====================================================================
-- Tabela: jogadores
-- =====================================================================
CREATE TABLE jogadores (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    nacionalidade VARCHAR(50),
    funcao VARCHAR(20) CHECK (funcao IN ('Goleiro', 'Zagueiro', 'Meio-campista', 'Atacante')),
    altura_cm SMALLINT CHECK (altura_cm > 100 AND altura_cm < 230),
    data_nascimento DATE,
    idade SMALLINT CHECK (idade > 15 AND idade < 50),
    valor_mercado_eur NUMERIC(12,2),
    clube_anterior VARCHAR(100)
);

-- =====================================================================
-- Tabela: contratos_jogador
-- =====================================================================
CREATE TABLE contratos_jogador (
    id SERIAL PRIMARY KEY,
    jogador_id INTEGER NOT NULL REFERENCES jogadores(id),
    data_contratacao DATE NOT NULL,
    data_expiracao_contrato DATE,
    ativo BOOLEAN DEFAULT TRUE
);

-- =====================================================================
-- Tabela: estatisticas_time_competicao
-- 1 linha por time por competicao
-- =====================================================================
CREATE TABLE estatisticas_time_competicao (
    id SERIAL PRIMARY KEY,
    time_id INTEGER NOT NULL REFERENCES times(id),
    competicao_id INTEGER NOT NULL REFERENCES competicoes(id),

    -- Resumo
    res_nota_sofascore NUMERIC(3,2),
    res_partidas INTEGER,
    res_gols_marcados INTEGER,
    res_gols_sofridos INTEGER,
    res_assistencias INTEGER,

    -- Desempenho de corrida (por partida)
    cor_distancia_percorrida_km NUMERIC(5,1),
    cor_numero_sprints NUMERIC(5,1),

    -- Atacando
    atk_gols_por_partida NUMERIC(4,2),
    atk_gols_penalti_marcados INTEGER,
    atk_gols_penalti_tentados INTEGER,
    atk_gols_falta_marcados INTEGER,
    atk_gols_falta_tentados INTEGER,
    atk_gols_dentro_area_marcados INTEGER,
    atk_gols_dentro_area_tentados INTEGER,
    atk_gols_fora_area_marcados INTEGER,
    atk_gols_fora_area_tentados INTEGER,
    atk_gols_perna_esquerda INTEGER,
    atk_gols_perna_direita INTEGER,
    atk_gols_cabeca INTEGER,
    atk_grandes_chances_por_jogo NUMERIC(4,2),
    atk_grandes_chances_perdidas_por_jogo NUMERIC(4,2),
    atk_finalizacoes_totais_por_jogo NUMERIC(4,2),
    atk_chutes_certos_por_jogo NUMERIC(4,2),
    atk_chutes_errados_por_jogo NUMERIC(4,2),
    atk_chutes_bloqueados_por_jogo NUMERIC(4,2),
    atk_dribles_certos_por_jogo NUMERIC(4,2),
    atk_escanteios_por_jogo NUMERIC(4,2),
    atk_faltas_tiros_diretos_por_jogo NUMERIC(4,2),
    atk_finalizacoes_na_trave INTEGER,
    atk_contra_ataques INTEGER,

    -- Passes
    pas_posse_bola_pct NUMERIC(4,1),
    pas_passes_certos_qtd INTEGER,
    pas_passes_certos_pct NUMERIC(4,1),
    pas_passes_proprio_campo_qtd INTEGER,
    pas_passes_proprio_campo_pct NUMERIC(4,1),
    pas_passes_certos_terco_final_qtd INTEGER,
    pas_passes_certos_terco_final_pct NUMERIC(4,1),
    pas_bolas_longas_qtd INTEGER,
    pas_bolas_longas_pct NUMERIC(4,1),
    pas_cruzamentos_certos_qtd INTEGER,
    pas_cruzamentos_certos_pct NUMERIC(4,1),

    -- Defendendo
    def_jogos_sem_sofrer_gols INTEGER,
    def_gols_sofridos_por_jogo NUMERIC(4,2),
    def_desarmes_por_jogo NUMERIC(4,2),
    def_interceptacoes_por_jogo NUMERIC(4,2),
    def_cortes_por_jogo NUMERIC(4,2),
    def_defesas_por_jogo NUMERIC(4,2),
    def_bolas_recuperadas_por_jogo NUMERIC(4,2),
    def_erros_levaram_finalizacao INTEGER,
    def_erros_levaram_gol INTEGER,
    def_penaltis_cometidos INTEGER,
    def_gols_penalti_concedidos INTEGER,
    def_tirar_cima_linha INTEGER,
    def_ultimo_homem_desarmar INTEGER,

    -- Outros
    out_desarmes_por_partida_qtd NUMERIC(4,1),
    out_desarmes_por_partida_pct NUMERIC(4,1),
    out_duelos_ganhos_chao_qtd NUMERIC(4,1),
    out_duelos_ganhos_chao_pct NUMERIC(4,1),
    out_duelos_aereos_ganhos_qtd NUMERIC(4,1),
    out_duelos_aereos_ganhos_pct NUMERIC(4,1),
    out_perda_posse_bola_por_jogo NUMERIC(4,1),
    out_laterais_por_jogo NUMERIC(4,1),
    out_tiros_meta_por_jogo NUMERIC(4,1),
    out_impedimentos_por_jogo NUMERIC(4,1),
    out_faltas_por_jogo NUMERIC(4,1),
    out_cartoes_amarelos_por_partida NUMERIC(4,1),
    out_cartoes_vermelhos INTEGER
);

-- =====================================================================
-- Tabela: estatisticas_jogador_competicao
-- 1 linha por jogador por competicao
-- =====================================================================
CREATE TABLE estatisticas_jogador_competicao (
    id SERIAL PRIMARY KEY,
    jogador_id INTEGER NOT NULL REFERENCES jogadores(id),
    competicao_id INTEGER NOT NULL REFERENCES competicoes(id),

    -- Resumo / Partidas
    res_jogos INTEGER,
    res_titular INTEGER,
    res_minutos_por_jogo INTEGER,
    res_total_minutos_jogados INTEGER,
    res_gols INTEGER,
    res_gols_esperados_xG NUMERIC(4,2),
    res_assistencias INTEGER,

    -- Desempenho de corrida (por 90)
    cor_distancia_percorrida_km_por_90 NUMERIC(4,1),
    cor_numero_sprints_por_90 NUMERIC(4,1),
    cor_velocidade_maxima_kmh NUMERIC(4,1),

    -- Atacando
    atk_frequencia_gols_minutos INTEGER,
    atk_gols_por_partida NUMERIC(4,2),
    atk_finalizacoes_por_jogo NUMERIC(4,2),
    atk_chutes_certos_por_jogo NUMERIC(4,2),
    atk_grandes_chances_perdidas INTEGER,
    atk_conversao_gols_pct NUMERIC(4,1),
    atk_gols_penalti_marcados INTEGER,
    atk_gols_penalti_tentados INTEGER,
    atk_conversao_penaltis_pct NUMERIC(4,1),
    atk_gols_falta_marcados INTEGER,
    atk_gols_falta_tentados INTEGER,
    atk_eficacia_gols_falta_pct NUMERIC(4,1),
    atk_gols_dentro_area_marcados INTEGER,
    atk_gols_dentro_area_tentados INTEGER,
    atk_gols_fora_area_marcados INTEGER,
    atk_gols_fora_area_tentados INTEGER,
    atk_gols_cabeca INTEGER,
    atk_gols_perna_esquerda INTEGER,
    atk_gols_perna_direita INTEGER,
    atk_penalti_sofrido INTEGER,

    -- Passe
    pas_assistencias_esperadas_xA NUMERIC(4,2),
    pas_acoes_com_bola NUMERIC(4,1),
    pas_grandes_chances_criadas INTEGER,
    pas_passes_decisivos NUMERIC(4,2),
    pas_passes_certos_qtd NUMERIC(4,1),
    pas_passes_certos_pct NUMERIC(4,1),
    pas_passes_proprio_campo_qtd NUMERIC(4,1),
    pas_passes_proprio_campo_pct NUMERIC(4,1),
    pas_passes_certos_terco_final_qtd NUMERIC(4,1),
    pas_passes_certos_terco_final_pct NUMERIC(4,1),
    pas_bolas_longas_certas_qtd NUMERIC(4,1),
    pas_bolas_longas_certas_pct NUMERIC(4,1),
    pas_passes_tensos_certos_qtd NUMERIC(4,1),
    pas_passes_tensos_certos_pct NUMERIC(4,1),
    pas_cruzamentos_certos_qtd NUMERIC(4,1),
    pas_cruzamentos_certos_pct NUMERIC(4,1),

    -- Defendendo
    def_interceptacoes_por_jogo NUMERIC(4,1),
    def_desarmes_por_jogo NUMERIC(4,1),
    def_bolas_recuperadas_ataque_por_jogo NUMERIC(4,1),
    def_bolas_recuperadas_por_jogo NUMERIC(4,1),
    def_driblado_por_jogo NUMERIC(4,1),
    def_cortes_por_jogo NUMERIC(4,1),
    def_chutes_bloqueados_por_jogo NUMERIC(4,1),
    def_erros_levaram_finalizacao INTEGER,
    def_erros_levaram_gol INTEGER,
    def_penaltis_cometidos INTEGER,

    -- Outros (por partida)
    out_dribles_certos_qtd NUMERIC(4,1),
    out_dribles_certos_pct NUMERIC(4,1),
    out_disputas_bola_vencidas_qtd NUMERIC(4,1),
    out_disputas_bola_vencidas_pct NUMERIC(4,1),
    out_duelos_ganhos_chao_qtd NUMERIC(4,1),
    out_duelos_ganhos_chao_pct NUMERIC(4,1),
    out_duelos_aereos_ganhos_qtd NUMERIC(4,1),
    out_duelos_aereos_ganhos_pct NUMERIC(4,1),
    out_perda_posse_bola NUMERIC(4,1),
    out_faltas_por_jogo NUMERIC(4,1),
    out_faltas_sofridas NUMERIC(4,1),
    out_impedimentos NUMERIC(4,1),

    -- Cartoes
    car_cartoes_amarelos INTEGER,
    car_cartoes_vermelhos_2_amarelos INTEGER,
    car_cartoes_vermelhos_diretos INTEGER
);

-- =====================================================================
-- Constraints UNIQUE (necessarias para upsert / ON CONFLICT futuro)
-- =====================================================================
ALTER TABLE estatisticas_time_competicao
ADD CONSTRAINT uq_time_competicao UNIQUE (time_id, competicao_id);

ALTER TABLE estatisticas_jogador_competicao
ADD CONSTRAINT uq_jogador_competicao UNIQUE (jogador_id, competicao_id);