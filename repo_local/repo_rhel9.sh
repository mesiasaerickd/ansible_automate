#!/bin/bash
# Autor: Erick Mesias
# Comentario: v1
# Script - Implementación repositorio centralizado

# Variables
BASE_DIR=/var/www/html
BASEOS_DIR=$BASE_DIR/rhel-9-for-x86_64-baseos-rpms
APPSTREAM_DIR=$BASE_DIR/rhel-9-for-x86_64-appstream-rpms


######## Inicio Desde aquí solo se ejecuta la primera vez ###########

# Instalar Apache (HTTP server) y herramientas necesarias
echo "[INFO] Instalando Apache y paquetes necesarios..."
dnf install -y httpd yum-utils createrepo epel-release

# Habilitar Apache
echo "[INFO] Habilitando y arrancando Apache..."
systemctl enable --now httpd

# Configurar firewalld para permitir HTTP
echo "[INFO] Configurando firewalld..."
firewall-cmd --permanent --add-service=http
firewall-cmd --reload

# Crear directorios necesarios
echo "[INFO] Creando directorios del repositorio..."
mkdir -p "$BASEOS_DIR"
mkdir -p "$APPSTREAM_DIR"

# Habilitar repositorios Red Hat (opcional si es que no lo tienes)
echo "[INFO] Habilitando repositorios Red Hat..."
subscription-manager repos --enable=rhel-9-for-x86_64-baseos-rpms
subscription-manager repos --enable=rhel-9-for-x86_64-appstream-rpms

######## FIN Primera implementación #############################

#  Limpiar caché DNF
echo "[INFO] Limpiando caché DNF..."
rm -rf /var/cache/dnf

yum module list &>/dev/null
yum updateinfo &>/dev/null

#  Sincronizar repositorios
echo "[INFO] Sincronizando repositorios..."
reposync -p $BASE_DIR --download-metadata --newest-only --delete --repo=rhel-9-for-x86_64-baseos-rpms
reposync -p $BASE_DIR --download-metadata --newest-only --delete --repo=rhel-9-for-x86_64-appstream-rpms

# Procesar BaseOS
echo "[INFO] Procesando BaseOS..."
cd $BASEOS_DIR || exit 1
cp $(find /var/cache/dnf/rhel-9-for-x86_64-baseos-rpms* -name "*comps.xml") comps.xml
createrepo -v -g comps.xml $BASEOS_DIR
gunzip $(find /var/cache/dnf/rhel-9-for-x86_64-baseos-rpms* -name "*modules.yaml.gz") -c > modules.yaml
modifyrepo modules.yaml repodata/
gunzip $(find /var/cache/dnf/rhel-9-for-x86_64-baseos-rpms* -name "*updateinfo.xml.gz") -c > updateinfo.xml
modifyrepo updateinfo.xml repodata/

# Procesar AppStream
echo "[INFO] Procesando AppStream..."
cd $APPSTREAM_DIR || exit 1
cp $(find /var/cache/dnf/rhel-9-for-x86_64-appstream-rpms* -name "*comps.xml") comps.xml
createrepo -v -g comps.xml $APPSTREAM_DIR
gunzip $(find /var/cache/dnf/rhel-9-for-x86_64-appstream-rpms* -name "*modules.yaml.gz") -c > modules.yaml
modifyrepo modules.yaml repodata/
gunzip $(find /var/cache/dnf/rhel-9-for-x86_64-appstream-rpms* -name "*updateinfo.xml.gz") -c > updateinfo.xml
modifyrepo updateinfo.xml repodata/

# Ajustar permisos
echo "[INFO] Ajustando permisos..."
chmod -R 644 $BASEOS_DIR
find $BASEOS_DIR -type d -exec chmod 755 {} +
chmod -R 644 $APPSTREAM_DIR
find $APPSTREAM_DIR -type d -exec chmod 755 {} +

# Finalización
echo "[INFO] Repositorio implementado y sincronizado correctamente desde cero."

##### Inicio - Configuración repositorio En el cliente Rhel ######

cat > /etc/yum.repos.d/rhel9-local.repo <<EOF
[rhel9-baseos-local]
name=RHEL9 BaseOS Local Repo
baseurl=http://<IP_DEL_REPO>/repos/rhel9/baseos/
enabled=1
gpgcheck=0

[rhel9-appstream-local]
name=RHEL9 AppStream Local Repo
baseurl=http://<IP_DEL_REPO>/repos/rhel9/appstream/
enabled=1
gpgcheck=0
EOF

##### Fin Configuración ##########################################

# En caso lo quieras programar con Cron
0 2 * * 0 /usr/local/bin/repo_rhel9.sh >> /var/log/repo_rhel9.log 2>&1
