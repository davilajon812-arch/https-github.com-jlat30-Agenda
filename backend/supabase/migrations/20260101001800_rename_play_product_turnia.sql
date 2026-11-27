-- "Citaly" chocaba con una app publicada en Play (com.citaly.app), así que el
-- nombre definitivo es Turnia. El product ID es solo un identificador: aún no
-- existe ningún producto en Play Console, así que el cambio no afecta compras.
update public.plans
set play_product_id = replace(play_product_id, 'citaly_', 'turnia_')
where play_product_id like 'citaly\_%';
