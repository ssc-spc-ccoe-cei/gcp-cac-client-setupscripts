# Script de préparation du projet Google Cloud

Ce script prépare un projet Google Cloud pour la solution Compliance as Code (CaC). Il gère la configuration des API, des rôles IAM personnalisés et des comptes de service nécessaires au fonctionnement du script.

- [Objectif](#objectif)
- [Prérequis et variables d'environnement](#prerequisites--environment-variables)
- [Configuration](#configuration)
- [Exécution du script](#execution-du-script)
- [changes](#changes)


## Objectif

L'objectif principal de ce script est d'automatiser la configuration d'un compte de service Google Cloud pour effectuer les vérifications de conformité nécessaires. Voici ce que font les fichiers :

```sh
.
├── clean.sh                          # nettoyer/supprimer toutes les ressources créées pour le compte de service 
├── custom_roles                      # fichiers yaml avec des définitions de rôles personnalisés
│   ├── cac-run-role.yaml             
│   ├── cac-scheduler-role.yaml
│   ├── cac-storage-object-role.yaml
│   └── cac-storage-role.yaml
├── functions.sh                      # script contenant toutes les fonctions dont nous avons besoin
├── logs                              # répertoire stockant tous les journaux
├── preflight.sh                      # script de pré-vérification pour tester les permissions, l'accès requis, PROJECT_ID
├── project_prep.sh                   # script principal pour créer un compte de service 
├── README_EN.md                      # instructions en anglais
└── README_FR.md                      # instructions en français
```

## Prérequis et variables d'environnement

Le script `preflight.sh` vérifie que les prérequis sont en place :

```sh
export PROJECT_ID="your-project-id"
cd gcp-cac-client-setupscripts/project_setup
./preflight.sh
```

Si vous recevez une erreur ici telle que:
```sh
ERROR: (gcloud.the.resource.permission) HTTPError 403: your-username@domain.ca does not have the.resource.permission access to the Google Cloud project. Permission 'the.resource.permission' denied on resource (or it may not exist). This command is authenticated as your-username@domain.ca which is the active account specified by the [core/account] property.
```
Vous pouvez essayer d'accorder à votre propre utilisateur ce rôle dans la console IAM `https://console.cloud.google.com/iam-admin/iam?project=<PROJECT_ID>` ou contacter l'administrateur pour vous accorder l'accès requis.
   
## Setup

Le script est composé de deux fichiers principaux:

-   `project_prep.sh`: Le script principal qui orchestre le processus de configuration.
-   `functions.sh`: Une collection de fonctions d'aide pour la journalisation, l'exécution des commandes et les étapes de configuration
-   `clean.sh`: Un script utilisé pour supprimer les ressources du compte de service, ses liaisons et le bucket GCS. À des fins de test

Le processus de configuration est divisé en les étapes suivantes:

1.  **Sélection de la langue**: Invite l'utilisateur à sélectionner une langue pour la sortie du script.
2.  **Initialisation**: Configure les fichiers journaux pour le suivi de l'exécution.
3.  **Validation des prérequis**: Vérifie le PROJECT_ID, vérifie le numéro du projet, l'état de la facturation et l'ID de l'organisation
4.  **Activation de l'API**: Active une liste d'API Google Cloud nécessaires
5.  **Création de rôles personnalisés**: Crée des rôles IAM personnalisés requis pour la solution CaC à partir des fichiers .yaml situés dans le répertoire custom_roles.
6.  **Configuration du compte de service**: Crée un compte de service principal et lui attribue un ensemble de rôles prédéfinis et personnalisés au niveau du projet et de l'organisation. Il nettoie également les rôles hérités.
7.  **Création d'identités de service**: Crée des identités de service pour divers services Google Cloud.
8.  **Achèvement**: Imprime un résumé des comptes de service créés.

## Exécution du script

Pour exécuter le script, accédez au répertoire project_setup et exécutez le script lui-même :

```sh
export PROJECT_ID="your-project-id"     # requis. Le nom de votre projet 
export LANGUAGE=                        # optionnelle que vous pouvez définir sur "en" "fr" si vous souhaitez ignorer la sélection de la langue  
./project_prep.sh
```
## changements et prochains éléments

### changements
1. Fonctions séparées dans un autre script
2. La seule variable d'environnement requise est le nom du projet export PROJECT_ID="name-of-project"
3. Readme ajouté en EN et FR
4. Format de journalisation un peu plus amélioré. Journaux dans un dossier séparé
5. Variable d'environnement optionnelle pour LANGUAGE. Peut être 'en' ou 'fr' pour ignorer l'invite
