-- "Turnia" también chocaba (nombre usado por otras apps del rubro de turnos),
-- así que el nombre definitivo es Citurno y el paquete com.jlaburto.citurno.
-- El product ID es solo un identificador: no existe aún en Play Console.
update public.plans
set play_product_id = replace(play_product_id, 'turnia_', 'citurno_')
where play_product_id like 'turnia\_%';
