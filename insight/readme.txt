Para la ejecución se esta utilizando un secreto para la autenticación
el servidor ansible tiene que estar registrado en insights
el servidor ansible es el unico que tiene que tener salida a internet al dominio de insight

ejecución
ansible-playbook -i inventario pbd_lnx_insights_offline.yaml --vault-password-file=secrets/pase.txt -l localhost,test
