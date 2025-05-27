#!/bin/bash

# Auteur : Christophe Casalegno / Brain 0verride
# Version corrigée pour affichage correct du labyrinthe

# Variables globales
brain="@"
trace="."
wall="█"
maze_source="maze.txt"
declare -A maze

# Fonction pour choisir la difficulté
function choose_difficulty() {
    clear
    echo "Choisissez votre niveau de difficulté :"
    echo "1 : Facile (31x15)"
    echo "2 : Normal (51x19)"
    echo "3 : Difficile (71x23)"
    read -p "Entrez votre choix : " difficulty

    case $difficulty in
        1) maze_cols=31; maze_rows=15 ;;
        2) maze_cols=51; maze_rows=19 ;;
        3) maze_cols=71; maze_rows=23 ;;
        *) maze_cols=31; maze_rows=15 ;;
    esac
}

# Générer un labyrinthe
function generate_maze() {
    local width=$1
    local height=$2

    for ((y=0; y<$height; y++)); do
        for ((x=0; x<$width; x++)); do
            maze[$y,$x]=1
        done
    done

    # Point de départ et de sortie
    maze[1,0]=0
    maze[$((height-2)),$((width-1))]=0

    function carve() {
        local cx=$1 cy=$2
        local directions=(0 1 2 3)
        directions=( $(shuf -e "${directions[@]}") )
        for direction in "${directions[@]}"; do
            local nx=$cx ny=$cy
            case $direction in
                0) ny=$((cy-2)) ;; # Haut
                1) nx=$((cx+2)) ;; # Droite
                2) ny=$((cy+2)) ;; # Bas
                3) nx=$((cx-2)) ;; # Gauche
            esac
            if ((nx > 0 && ny > 0 && nx < width-1 && ny < height-1)); then
                if [[ ${maze[$ny,$nx]} -eq 1 ]]; then
                    maze[$((cy+(ny-cy)/2)),$((cx+(nx-cx)/2))]=0
                    maze[$ny,$nx]=0
                    carve $nx $ny
                fi
            fi
        done
    }

    carve 1 1
    save_maze $width $height
}

# Sauvegarder le labyrinthe dans un fichier
function save_maze() {
    local width=$1 height=$2
    > $maze_source
    for ((y=0; y<$height; y++)); do
        for ((x=0; x<$width; x++)); do
            if [[ ${maze[$y,$x]} -eq 1 ]]; then
                printf "$wall" >> $maze_source
            else
                printf " " >> $maze_source
            fi
        done
        echo >> $maze_source
    done
}

# Initialiser le labyrinthe
function init_maze() {
    local y=0
    while IFS= read -r line; do
        for ((x=0; x<${#line}; x++)); do
            maze[$y,$x]="${line:x:1}"
        done
        ((y++))
    done < "$maze_source"
}

# Afficher le labyrinthe
function print_maze() {
    clear
    for ((y=0; y<$maze_rows; y++)); do
        for ((x=0; x<$maze_cols; x++)); do
            if [[ $y -eq $player_y && $x -eq $player_x ]]; then
                printf "$brain"
            else
                printf "${maze[$y,$x]}"
            fi
        done
        echo
    done
}

# Vérifier si le joueur a gagné
function check_victory() {
    if [[ $player_y -eq $((maze_rows-2)) && $player_x -eq $((maze_cols-1)) ]]; then
        echo "Félicitations, vous avez gagné !"
        exit 0
    fi
}

# Boucle principale
function game_loop() {
    while true; do
        print_maze
        echo "Position actuelle : (x=$player_x, y=$player_y)"

        read -rsn1 input
        case $input in
            w) next_x=$player_x; next_y=$((player_y-1)) ;; # Haut
            s) next_x=$player_x; next_y=$((player_y+1)) ;; # Bas
            a) next_x=$((player_x-1)); next_y=$player_y ;; # Gauche
            d) next_x=$((player_x+1)); next_y=$player_y ;; # Droite
            *) continue ;;
        esac

        if [[ ${maze[$next_y,$next_x]} == " " ]]; then
            player_x=$next_x
            player_y=$next_y
        fi

        check_victory
    done
}

# Démarrer le jeu
function start_game() {
    choose_difficulty
    generate_maze $maze_cols $maze_rows
    init_maze
    player_x=0
    player_y=1
    game_loop
}

start_game
