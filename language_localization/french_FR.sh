LANG_SUCCESS="[SUCCÈS]"
LANG_FAILURE="[ÉCHEC]"
LANG_PREFLIGHT_FAILED_EXITING="Vérification préalable échouée. Abandon."
LANG_GCLOUD_NOT_INSTALLED="L'interface CLI gcloud n'est pas installée. Veuillez l'installer et réessayer."
LANG_GCLOUD_INSTALLED="L'interface CLI gcloud est installée."
LANG_NO_PROJECT_SET="Aucun projet GCP n'est défini. Veuillez définir un nom de projet avec 'export PROJECT_ID=votre-projet-nom' et réessayer."
LANG_PROJECT_SET="Le projet GCP est défini sur"
LANG_MISSING_ROLE="Rôle requis manquant :"
LANG_MISSING_ROLE_SUFFIX="Veuillez vous assurer que vous disposez des autorisations nécessaires."
LANG_ROLE_PRESENT="Rôle requis présent :"
LANG_GCS_PERMISSIONS_OK="Vous avez les autorisations pour créer des buckets GCS dans le projet."
LANG_GCS_PERMISSIONS_FAIL="Vous n'avez pas les autorisations pour créer des buckets GCS dans le projet. Veuillez vous assurer que vous disposez des autorisations nécessaires."
LANG_COMPLETION_BANNER="┌───────────────────────────────────────────────────────┐\n│                                                       │\n│   Préparation de l'environnement CaC terminée avec succès  │\n│                                                       │\n└───────────────────────────────────────────────────────┘"
LANG_SERVICE_ACCOUNT_INFO="  Informations sur les comptes de service pour SSC :"
LANG_COMPLIANCE_TOOL_SA="  Compte de service Compliance Tool : "
LANG_CLOUD_RUN_ROBOT_ACCOUNT="  Compte Robot Cloud Run :          "
LANG_STORAGE_TRANSFER_ROBOT_ACCOUNT="  Compte Robot Storage Transfer :   "
LANG_BINARY_AUTH_ROBOT_ACCOUNT="  Compte Robot Binary Auth :        "
LANG_ENABLING_SERVICE="Activation du service :"
LANG_COULD_NOT_ENABLE_SERVICE="Impossible d'activer"
LANG_CONFIGURING_ROLE="Configuration du rôle :"
LANG_FAILED_CREATE_OR_UPDATE_ROLE="Échec de la création ou de la mise à jour du rôle"
LANG_GRANTING_ROLE="Attribution du rôle :"
LANG_FAILED_GRANT_ROLE="Échec de l'attribution du rôle"
LANG_GRANTING_CUSTOM_ROLE="Attribution du rôle personnalisé :"
LANG_FAILED_GRANT_CUSTOM_ROLE="Échec de l'attribution du rôle personnalisé"
LANG_GRANTING_ORG_ROLE="Attribution du rôle d'organisation :"
LANG_FAILED_GRANT_ORG_ROLE="Échec de l'attribution du rôle d'organisation. Vérifiez vos permissions sur l'ID d'organisation :"
LANG_CREATING_IDENTITY_FOR="Création d'une identité pour :"
LANG_COULD_NOT_CREATE_IDENTITY_FOR="Impossible de créer une identité pour"
LANG_GRANTING_STORAGE_VIEWER_TO_TRANSFER_SERVICE="Attribution du rôle Storage Viewer au service de transfert"
LANG_FAILED_GRANT_ROLE_TO_TRANSFER_SERVICE_AGENT="Échec de l'attribution du rôle à l'agent du service de transfert."
LANG_GRANTING_CUSTOM_STORAGE_ROLE_TO_ASSET_SERVICE="Attribution du rôle de stockage personnalisé au service Cloud Asset"
LANG_FAILED_GRANT_CUSTOM_ROLE_TO_ASSET_AGENT="Échec de l'attribution du rôle personnalisé à l'agent Cloud Asset."
LANG_CREATING_GCS_BUCKET="Création du bucket GCS :"
LANG_FAILED_CREATE_GCS_BUCKET="Échec de la création du bucket GCS"
LANG_UPLOADING_SERVICE_ACCOUNT_INFO="Téléversement des informations du compte de service vers le bucket GCS"
LANG_FAILED_UPLOAD_SERVICE_ACCOUNT_INFO="Échec du téléversement des informations du compte de service vers le bucket GCS. Vérifiez si le bucket existe et si vous avez les permissions nécessaires pour y écrire."
LANG_PROJECT_ID_VERIFIED="ID du projet vérifié avec succès :"
LANG_PROJECT_NUMBER_VERIFIED="Numéro de projet vérifié avec succès :"
LANG_BILLING_ENABLED="La facturation est activée pour"
LANG_ORG_ID_VERIFIED="ID d'organisation vérifié avec succès :"
LANG_REMOVING_LEGACY_ROLE="Suppression de l'ancien rôle :"
LANG_COULD_NOT_REMOVE_ROLE="Impossible de supprimer le rôle"
LANG_CHECKING_PREREQS="INFO : Vérification des prérequis..."
LANG_VERIFYING_PROJECT_ID="INFO : Vérification de l'ID du projet..."
LANG_FETCHING_PROJECT_NUMBER="INFO : Récupération du numéro du projet..."
LANG_CHECKING_BILLING_STATUS="INFO : Vérification de l'état de la facturation pour l'ID du projet : $PROJECT_ID"
LANG_VERIFYING_ORG_ID="INFO : Vérification de l'ID de l'organisation..."
LANG_CREATING_LOG_FILES="INFO : Création des fichiers journaux..."
LANG_SETTING_UP_CUSTOM_ROLES="Configuration des rôles personnalisés..."
LANG_CLEANING_UP_LEGACY_ROLES="Nettoyage des anciens rôles..."
LANG_GRANTING_PROJECT_ROLES="Attribution des rôles de projet..."
LANG_GRANTING_CUSTOM_ROLES="Attribution des rôles personnalisés..."
LANG_GRANTING_ORG_ROLES="Attribution des rôles d'organisation..."
LANG_GCS_BUCKET_EXISTS="Le bucket GCS existe déjà. Création ignorée."
LANG_GRANTING_ROLES_TO_SERVICE_IDENTITIES="Attribution des rôles aux identités de service Google..."
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
LANG_OWNER_ROLE_PRESENT="L'utilisateur a le rôle de propriétaire, sauts de vérification de rôle individuels."
