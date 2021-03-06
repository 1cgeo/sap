/*
    Verifica se existe alguma atividade disponível para o usuário na fila de atividades de seu perfil
*/
SELECT id
FROM (
  SELECT ee.id, ee.etapa_id, ee.unidade_trabalho_id, ee_ant.tipo_situacao_id AS situacao_ant, lo.prioridade AS lo_prioridade, pse.prioridade AS pse_prioridade, ut.prioridade AS ut_prioridade
  FROM macrocontrole.atividade AS ee
  INNER JOIN macrocontrole.perfil_producao_etapa AS pse ON pse.etapa_id = ee.etapa_id
  INNER JOIN macrocontrole.perfil_producao_operador AS ppo ON ppo.perfil_producao_id = pse.perfil_producao_id
  INNER JOIN dgeo.usuario AS u ON u.id = ppo.usuario_id
  INNER JOIN macrocontrole.etapa AS se ON se.id = ee.etapa_id
  INNER JOIN macrocontrole.unidade_trabalho AS ut ON ut.id = ee.unidade_trabalho_id
  INNER JOIN macrocontrole.lote AS lo ON lo.id = ut.lote_id
  LEFT JOIN
  (
    SELECT ee.tipo_situacao_id, ee.unidade_trabalho_id, se.ordem, se.subfase_id FROM macrocontrole.atividade AS ee
    INNER JOIN macrocontrole.etapa AS se ON se.id = ee.etapa_id
    WHERE ee.tipo_situacao_id in (1,2,3,4)
  ) 
  AS ee_ant ON ee_ant.unidade_trabalho_id = ee.unidade_trabalho_id AND ee_ant.subfase_id = se.subfase_id
  AND se.ordem > ee_ant.ordem
  WHERE ut.disponivel IS TRUE AND ppo.usuario_id = $1 AND ee.tipo_situacao_id = 1
  AND ee.id NOT IN
  (
    SELECT a.id FROM macrocontrole.atividade AS a
    INNER JOIN macrocontrole.perfil_producao_etapa AS ppe ON ppe.etapa_id = a.etapa_id
    INNER JOIN macrocontrole.perfil_producao_operador AS ppo ON ppo.perfil_producao_id = ppe.perfil_producao_id
    INNER JOIN macrocontrole.unidade_trabalho AS ut ON ut.id = a.unidade_trabalho_id
    INNER JOIN macrocontrole.pre_requisito_subfase AS prs ON prs.subfase_posterior_id = ut.subfase_id
    INNER JOIN macrocontrole.unidade_trabalho AS ut_re ON ut_re.subfase_id = prs.subfase_anterior_id
    INNER JOIN macrocontrole.atividade AS a_re ON a_re.unidade_trabalho_id = ut_re.id
    WHERE ppo.usuario_id = $1 AND prs.tipo_pre_requisito_id = 1 AND 
    ut.geom && ut_re.geom AND
    st_relate(ut.geom, ut_re.geom, '2********') AND
    a_re.tipo_situacao_id IN (1, 2, 3) AND a.tipo_situacao_id = 1
  )
  AND ee.id NOT IN
  (
    SELECT a.id FROM macrocontrole.atividade AS a
    INNER JOIN macrocontrole.perfil_producao_etapa AS ppe ON ppe.etapa_id = a.etapa_id
    INNER JOIN macrocontrole.perfil_producao_operador AS ppo ON ppo.perfil_producao_id = ppe.perfil_producao_id
    INNER JOIN macrocontrole.etapa AS et ON et.id = a.etapa_id
    INNER JOIN macrocontrole.subfase AS sub ON sub.id = et.subfase_id
    INNER JOIN macrocontrole.fase AS fa ON fa.id = sub.fase_id
    INNER JOIN dgeo.usuario AS u ON u.id = ppo.usuario_id
    INNER JOIN macrocontrole.unidade_trabalho AS ut ON ut.id = a.unidade_trabalho_id
    INNER JOIN macrocontrole.restricao_etapa AS re ON re.etapa_posterior_id = a.etapa_id
    INNER JOIN macrocontrole.etapa AS et_re ON et_re.id = re.etapa_anterior_id AND et_re.subfase_id != et.subfase_id
    INNER JOIN macrocontrole.subfase AS sub_re ON sub_re.id = et_re.subfase_id
    INNER JOIN macrocontrole.fase AS fa_re ON fa_re.id = sub_re.fase_id AND fa_re.linha_producao_id = fa.linha_producao_id
    INNER JOIN macrocontrole.atividade AS a_re ON a_re.etapa_id = et_re.id
    INNER JOIN dgeo.usuario AS u_re ON u_re.id = a_re.usuario_id
    INNER JOIN macrocontrole.unidade_trabalho AS ut_re ON ut_re.id = a_re.unidade_trabalho_id AND ut.geom && ut_re.geom AND st_relate(ut.geom, ut_re.geom, '2********')
    WHERE ppo.usuario_id = $1 AND (
        (re.tipo_restricao_id = 1 AND a_re.usuario_id = $1) OR
        (re.tipo_restricao_id = 2 AND a_re.usuario_id != $1) OR 
        (re.tipo_restricao_id = 3 AND u_re.tipo_turno_id != u.tipo_turno_id AND u_re.tipo_turno_id != 3 AND u.tipo_turno_id != 3)
    ) AND a_re.tipo_situacao_id in (1,2,3,4)  AND a.tipo_situacao_id = 1
  )
  AND ee.id NOT IN
  (
    SELECT ee.id FROM macrocontrole.atividade AS ee
    INNER JOIN macrocontrole.perfil_producao_etapa AS pse ON pse.etapa_id = ee.etapa_id
    INNER JOIN macrocontrole.perfil_producao_operador AS ppo ON ppo.perfil_producao_id = pse.perfil_producao_id
    INNER JOIN macrocontrole.etapa AS et ON et.id = ee.etapa_id
    INNER JOIN dgeo.usuario AS u ON u.id = ppo.usuario_id
    INNER JOIN macrocontrole.restricao_etapa AS re ON re.etapa_posterior_id = ee.etapa_id
    INNER JOIN macrocontrole.atividade AS ee_re ON ee_re.etapa_id = re.etapa_anterior_id
      AND ee_re.unidade_trabalho_id = ee.unidade_trabalho_id
    INNER JOIN macrocontrole.etapa AS et_re ON et_re.id = ee_re.etapa_id
    INNER JOIN dgeo.usuario AS u_re ON u_re.id = ee_re.usuario_id
    WHERE ppo.usuario_id = $1 AND et_re.subfase_id = et.subfase_id AND (
      (re.tipo_restricao_id = 1 AND ee_re.usuario_id = $1) OR
      (re.tipo_restricao_id = 2 AND ee_re.usuario_id != $1) OR 
      (re.tipo_restricao_id = 3 AND u_re.tipo_turno_id != u.tipo_turno_id AND u_re.tipo_turno_id != 3 AND u.tipo_turno_id != 3)
    ) AND ee_re.tipo_situacao_id in (1,2,3,4) AND ee.tipo_situacao_id = 1
  )
  AND ee.id NOT IN
  (
    SELECT atividade_id FROM macrocontrole.fila_prioritaria
  )
  AND ee.id NOT IN
  (
    SELECT atividade_id FROM macrocontrole.fila_prioritaria_grupo
  )
) AS sit
GROUP BY id, lo_prioridade, pse_prioridade, ut_prioridade
HAVING MIN(situacao_ant) IS NULL OR every(situacao_ant IN (4)) 
ORDER BY lo_prioridade, pse_prioridade, ut_prioridade
LIMIT 1