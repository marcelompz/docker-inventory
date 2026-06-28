# Inventario de Puertos Docker - 2026-06-28 12:51

## Contenedores corriendo:
orderflow_db             0.0.0.0:5433->5432/tcp, [::]:5433->5432/tcp
orderflow_frontend       0.0.0.0:3011->3011/tcp, [::]:3011->3011/tcp
orderflow_odoo_adapter   0.0.0.0:3005->3005/tcp, [::]:3005->3005/tcp
orderflow_backend        3000/tcp, 0.0.0.0:3010->3010/tcp, [::]:3010->3010/tcp
axon-web-dev             0.0.0.0:5173->5173/tcp, [::]:5173->5173/tcp
axon-redis               0.0.0.0:6379->6379/tcp, [::]:6379->6379/tcp
axon-couchdb             4369/tcp, 9100/tcp, 0.0.0.0:5984->5984/tcp, [::]:5984->5984/tcp
axon-postgres            0.0.0.0:5432->5432/tcp, [::]:5432->5432/tcp

## Puertos en uso (sistema):
3005 3010 3011 3389 4000 5173 5355 5432 5433 5984 6379 7001 

## Proyectos en /opt:
- aier: sin puertos
- axon: 5173,5984
- axon-ecosystem: 5432,6379,5984,5173
- data-analysis: 5432,8000,3000
- LeadQualifierCRM: 5432,27017,6379,8000,3000
- mee: 5432,8000,3000
- odoo: sin puertos
- orderflow: 5433,3010,3011,3005
- pentaho: 8080,9080
- vitalog: sin puertos
