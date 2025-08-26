#!/bin/bash

# Script pour redistribuer les commits Git avec de nouveaux auteurs et dates
# ATTENTION: Ce script réécrit l'historique Git complètement

# Configuration des membres de l'équipe
TEAM_MEMBERS=(
    "Fisrtname Lastname <email>"
    "Fisrtname Lastname <email>"
)

# Configuration temporelle
START_DATE="2025-06-17" # Date de début pour les commits (YYYY-MM-DD)
MAX_COMMITS_PER_DAY=2   # Nombre maximum de commits par jour
WORK_START_HOUR=9
WORK_END_HOUR=20

# Couleurs pour les messages
RED='[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages colorés
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Vérification que nous sommes dans un repo Git
if [ ! -d ".git" ]; then
    log_error "Ce script doit être exécuté dans un dépôt Git"
    exit 1
fi

# Sauvegarde de la branche actuelle
CURRENT_BRANCH=$(git branch --show-current)
log_info "Branche actuelle: $CURRENT_BRANCH"

# Demande de confirmation
echo
log_warning "ATTENTION: Ce script va complètement réécrire l'historique Git!"
log_warning "Cela inclut:"
log_warning "- Modification de tous les commits existants"
log_warning "- Changement des dates et auteurs"
log_warning "- Redistribution temporelle des commits"
echo
read -p "Êtes-vous sûr de vouloir continuer? (oui/non): " confirmation

if [ "$confirmation" != "oui" ]; then
    log_info "Opération annulée"
    exit 0
fi

# Création d'une sauvegarde
BACKUP_BRANCH="backup-$(date +%Y%m%d-%H%M%S)"
git branch "$BACKUP_BRANCH"
log_info "Sauvegarde créée sur la branche: $BACKUP_BRANCH"

# Récupération de la liste des commits
log_info "Récupération de la liste des commits..."
git rev-list --reverse HEAD > /tmp/commits_list.txt
TOTAL_COMMITS=$(wc -l < /tmp/commits_list.txt)
log_info "Nombre total de commits: $TOTAL_COMMITS"

if [ $TOTAL_COMMITS -eq 0 ]; then
    log_error "Aucun commit trouvé"
    exit 1
fi

# Fonction pour générer une date aléatoire dans la plage de travail pour un jour donné (timestamp)
generate_random_date() {
    local day_timestamp=$1
    local last_timestamp_for_day=$2

    if [ "$last_timestamp_for_day" -eq 0 ]; then
        # Premier commit de la journée: heure de début aléatoire
        local random_hour=$((RANDOM % (WORK_END_HOUR - WORK_START_HOUR) + WORK_START_HOUR))
        local random_minute=$((RANDOM % 60))
        local random_second=$((RANDOM % 60))

        if [[ "$OSTYPE" == "darwin"* ]]; then
            local base_date_str=$(date -r "$day_timestamp" "+%Y-%m-%d")
            date -j -f "%Y-%m-%d %H:%M:%S" "$base_date_str $random_hour:$random_minute:$random_second" "+%s"
        else
            local base_date_str=$(date -d "@$day_timestamp" "+%Y-%m-%d")
            date -d "$base_date_str $random_hour:$random_minute:$random_second" "+%s"
        fi
    else
        # Commits suivants: ajouter un intervalle de temps
        local max_interval_minutes=120 # max 2 heures
        local min_interval_minutes=5   # min 5 minutes
        local interval_seconds=$(( (RANDOM % (max_interval_minutes - min_interval_minutes + 1) + min_interval_minutes) * 60 ))
        local new_timestamp=$((last_timestamp_for_day + interval_seconds))

        # Vérifier si la nouvelle heure dépasse les heures de travail
        local new_hour
        if [[ "$OSTYPE" == "darwin"* ]]; then
            new_hour=$(date -r "$new_timestamp" +%H)
        else
            new_hour=$(date -d "@$new_timestamp" +%H)
        fi

        if [ "$new_hour" -ge "$WORK_END_HOUR" ]; then
            # Si on dépasse, on plafonne à la fin de la journée de travail pour ce commit
            local end_of_day_timestamp
            if [[ "$OSTYPE" == "darwin"* ]]; then
                local base_date_str=$(date -r "$day_timestamp" "+%Y-%m-%d")
                end_of_day_timestamp=$(date -j -f "%Y-%m-%d %H:%M:%S" "$base_date_str $WORK_END_HOUR:00:00" "+%s")
            else
                local base_date_str=$(date -d "@$day_timestamp" "+%Y-%m-%d")
                end_of_day_timestamp=$(date -d "$base_date_str $WORK_END_HOUR:00:00" "+%s")
            fi
            
            if [ "$last_timestamp_for_day" -ge "$end_of_day_timestamp" ]; then
                 echo "$last_timestamp_for_day"
                 return
            fi
            # On s'assure de ne pas retourner en arrière
            if [ "$new_timestamp" -gt "$end_of_day_timestamp" ]; then
                echo "$end_of_day_timestamp"
            else
                echo "$new_timestamp"
            fi
            return
        fi
        echo "$new_timestamp"
    fi
}

# Fonction pour sélectionner un auteur aléatoire
get_random_author() {
    local index=$((RANDOM % ${#TEAM_MEMBERS[@]}))
    echo "${TEAM_MEMBERS[$index]}"
}

# Création du script de filtre pour git filter-branch
cat > /tmp/git_filter_script.sh << 'EOF'
#!/bin/bash

# Lecture des données pré-générées
COMMIT_DATA_FILE="/tmp/commit_data.txt"
CURRENT_COMMIT="$GIT_COMMIT"

# Recherche des données pour ce commit
while IFS='|' read -r orig_hash new_date new_author_name new_author_email; do
    if [ "$orig_hash" = "$CURRENT_COMMIT" ]; then
        export GIT_AUTHOR_NAME="$new_author_name"
        export GIT_AUTHOR_EMAIL="$new_author_email"
        export GIT_COMMITTER_NAME="$new_author_name"
        export GIT_COMMITTER_EMAIL="$new_author_email"
        export GIT_AUTHOR_DATE="$new_date"
        export GIT_COMMITTER_DATE="$new_date"
        break
    fi
done < "$COMMIT_DATA_FILE"
EOF

chmod +x /tmp/git_filter_script.sh

# Génération des nouvelles données pour chaque commit
log_info "Génération des nouvelles dates et auteurs..."

# Initialisation du compteur de commits par membre
commit_counts=()
for i in "${!TEAM_MEMBERS[@]}"; do
    commit_counts[$i]=0
done

commit_counter=0
commits_today=0

# Convertir la date de début en timestamp pour le calcul
if [[ "$OSTYPE" == "darwin"* ]]; then
    current_timestamp=$(date -j -f "%Y-%m-%d" "$START_DATE" "+%s")
else
    current_timestamp=$(date -d "$START_DATE" "+%s")
fi

last_commit_timestamp=0

# Création du fichier de données
> /tmp/commit_data.txt

while read -r commit_hash; do
    # Gestion de la distribution temporelle
    if [ $commits_today -ge $MAX_COMMITS_PER_DAY ]; then
        # Passer au jour suivant
        if [[ "$OSTYPE" == "darwin"* ]]; then
            current_timestamp=$(date -j -v+1d -f "%s" "$current_timestamp" "+%s")
        else
            current_timestamp=$(date -d "@$current_timestamp + 1 day" "+%s")
        fi
        commits_today=0
        last_commit_timestamp=0 # Réinitialiser pour le nouveau jour
    fi
    
    # Génération de la nouvelle date et auteur
    new_timestamp=$(generate_random_date $current_timestamp $last_commit_timestamp)
    last_commit_timestamp=$new_timestamp

    if [[ "$OSTYPE" == "darwin"* ]]; then
        commit_date=$(date -r "$new_timestamp" "+%Y-%m-%d %H:%M:%S %z")
    else
        commit_date=$(date -d "@$new_timestamp" "+%Y-%m-%d %H:%M:%S %z")
    fi
    
    author_index=$((RANDOM % ${#TEAM_MEMBERS[@]}))
    author="${TEAM_MEMBERS[$author_index]}"
    ((commit_counts[$author_index]++))
    
    # Extraction du nom et email
    author_name=$(echo "$author" | sed 's/ <.*>//')
    author_email=$(echo "$author" | sed 's/.*<\(.*\)>.*/\1/')
    
    # Sauvegarde dans le fichier de données
    echo "$commit_hash|$commit_date|$author_name|$author_email" >> /tmp/commit_data.txt
    
    commit_counter=$((commit_counter + 1))
    commits_today=$((commits_today + 1))
    progress=$((commit_counter * 100 / TOTAL_COMMITS))
    printf "\rPréparation: %d%% (%d/%d commits)" $progress $commit_counter $TOTAL_COMMITS
    
done < /tmp/commits_list.txt

echo # Nouvelle ligne après la barre de progression

# Application des modifications avec git filter-branch
log_info "Application des modifications..."

# Supprimer les refs de filter-branch précédentes si elles existent
rm -rf .git/refs/original/ 2>/dev/null

# Exécution de git filter-branch
FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch \
    --env-filter '. /tmp/git_filter_script.sh' \
    --tag-name-filter cat \
    -- --all

if [ $? -ne 0 ]; then
    log_error "Erreur lors de l'application de filter-branch"
    log_info "Restauration depuis la sauvegarde..."
    git reset --hard "$BACKUP_BRANCH"
    exit 1
fi

# Nettoyage des refs de sauvegarde de filter-branch
git update-ref -d refs/original/refs/heads/"$CURRENT_BRANCH" 2>/dev/null || true

log_info "Redistribution terminée!"
log_info "Sauvegarde disponible sur la branche: $BACKUP_BRANCH"

# Vérification du résultat
FINAL_COMMITS=$(git rev-list HEAD | wc -l)
log_info "Commits avant: $TOTAL_COMMITS, après: $FINAL_COMMITS"

if [ "$TOTAL_COMMITS" -ne "$FINAL_COMMITS" ]; then
    log_warning "Le nombre de commits a changé! Vérifiez le résultat."
fi

echo
echo "Résumé des modifications:"
echo "- Commits redistribués à partir du $START_DATE"
echo "- Maximum de $MAX_COMMITS_PER_DAY commits par jour"
echo "- Horaires de travail: ${WORK_START_HOUR}h-${WORK_END_HOUR}h"
echo "- ${#TEAM_MEMBERS[@]} auteurs dans l'équipe"
echo "- $TOTAL_COMMITS commits traités"
echo
echo "Répartition des commits par membre:"
for i in "${!TEAM_MEMBERS[@]}"; do
    member="${TEAM_MEMBERS[$i]}"
    count=${commit_counts[$i]}
    printf -- "- %-40s : %d commits\n" "$member" "$count"
done
echo
echo "Vérification rapide des derniers commits:"
git log --oneline -5

echo
log_warning "Pour supprimer la sauvegarde: git branch -D $BACKUP_BRANCH"
log_warning "Pour restaurer l'original: git reset --hard $BACKUP_BRANCH"

# Nettoyage des fichiers temporaires
rm -f /tmp/commits_list.txt /tmp/commit_data.txt /tmp/git_filter_script.sh
