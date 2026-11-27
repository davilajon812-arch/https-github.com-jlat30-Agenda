-- El paquete de Android pasa a com.citaly.app y la suscripción se creará en
-- Play Console con el nombre de la marca nueva. El product ID es solo un
-- identificador: hasta ahora ningún producto existía en Play, así que el
-- cambio no afecta a compras hechas.
update public.plans
set play_product_id = replace(play_product_id, 'agendapro_', 'citaly_')
where play_product_id like 'agendapro\_%';
