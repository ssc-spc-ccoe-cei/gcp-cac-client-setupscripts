PROMPT="
Veuillez confirmer en entrant de nouveau le nom:
>"

LANG_SETUP_PROMPT="
################################################################################
##      Collecte des informations requises                                 ##
################################################################################

"
LANG_VALIDATION_PROMPT="
################################################################################
##         Validation de l'information requise                                ##
################################################################################

"
LANG_DEPLOYMENT_PROMPT="
################################################################################
##     Lancement du déploiement de l'outil CaC                                ##
################################################################################

"

LANG_APIS="

INFO: Activation des services de projet requis : Cloud Run, Cloud Storage et Cloud Scheduler"

LANG_SA_SETUP="
INFO : Créer un compte de service CaC et ajouter des permissions"
LANG_SI_CREATE="

INFO : Création des identités de service Google
"

LANG_SERVICE_ACCOUNT="
Veuillez entrer le nom du compte de service:
>"

LANG_ORG_ID="
Veuillez entrer le numéro d’identification numérique de l’organisation du GCP:
>"
LANG_ORG_NAME="
Veuillez entrer le nom de l'organisation GCP:
>"
LANG_GC_PROFILE="
Veuillez entrer le niveau du profil d’utilisation du nuage de l’organisation (1-6):
>"
LANG_BUCKET="
Veuillez entrer l'URL du seau de stockage Google Cloud:
>"

LANG_POLICY="
Veuillez entrer l'adresse universelle (URL) du référentiel contenant les politiques de conformité:
>"

LANG_PROJECT="est détecté comme le projet associé à gcloud cli, 
appuyez sur Entrée pour continuer à utiliser ce projet 
ou entrez un nom de projet différent:
>"

LANG_REGION="
Veuillez sélectionner une région d’installation:
1) northamerica-northeast1 (Canada - Montréal)
2) northamerica-northeast2 (Canada - Toronto)
>"
LANG_CONFIG_PROMPT="
INFO: Fichier de configuration trouvé, l'installation utilisera les valeurs pour continuer
"

CONFIRM_PROJECT="
INFO: L'outil CaC sera déployé dans le projet"

CONFIRM_REGION="
INFO: L'outil CaC sera déployé dans la région"

CONFIRM_SERVICE_ACCOUNT="
INFO: L'outil CaC sera déployé en utilisant le compte de service"

SA_ERROR="
ERREUR : Compte de service non trouvé. Veuillez vérifier et réessayer"
" 

SA_POLICY_ERROR="
AVERTISSEMENT: Les permissions du compte de service sont surprovisionnées
"
SA_CURRENT_POLICY="
Les permissions actuelles sont:"
SA_REQUIRED_POLICY="
Les permissions requises sont:
"

BINDING_PROMPT="
INFO : Lier le compte de service à l’utilisateur principal..."
ROLE_VALIDATION_PROMPT="
INFO: Vérification de l'accès et des permissions du compte de service..."
ROLES_VALIDATION="
Rôle correctement attribué à  "
ROLES_VALIDATION_SUCCESS="
INFO: Validation des rôles requis pour le compte de service"
ROLES_VALIDATION_ERROR="
ERREUR: Le compte de service manque les rôles suivants:
"
POLICY_CONFIRMATION="
*** Êtes-vous certain de vouloir continuer? (y/n)
>"

POLICY_CONTINUE="
INFO: Déploiement continu"
POLICY_EXIT="Annulation du déploiement"

CAC_IMAGE="
Entrez l'image du conteneur à utiliser: 
>"
CAC_OPA_IMAGE="
Entrez l' OPA image du conteneur à utiliser: 
>"
CREATE_BUCKET="
INFO: CCréation d'un sceau-pivot pour la mise en conformité des mesures de protection du nuage GC ..."
CONFIG_BUCKET="
INFO: Configuration des classes de stockage et des versions..."
CREATE_FOLDERS="
INFO: Création de répertoires pour chaque mesures de protection du nuage GC..."
CREATE_CRUN="
INFO: Créer un service Cloud Run en arrière-plan..."
CREATE_CSCHEDULER="
INFO: Création de la cédule de travail de Cloud Scheduler..."
COMPLETED="
SUCCÈS: Le déploiement de l'outil CaC est complété"
