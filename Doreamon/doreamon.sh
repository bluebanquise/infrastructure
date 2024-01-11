#!/bin/bash
export PATH=$HOME/.local/bin:$PATH
CURRENT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
set -x
pip3 install --upgrade sphinx sphinx-book-theme mkdocs mkdocs-material
export PATH=$HOME/.local/bin:$PATH

# Grab credentials
source $HOME/credentials.sh

# Prepare gits
mkdir -p gits
cd gits
git clone https://github.com/bluebanquise/bluebanquise.git
git clone https://github.com/bluebanquise/infrastructure.git
git clone https://github.com/bluebanquise/website.git
cd ../

# Main loop
while [ 1 ]
do

    gits_bluebanquise_update=0
    gits_website_update=0
    gits_infrastructure_update=0
    # Check if manual build requested
    if test -f "gits_bluebanquise_update"; then
        gits_bluebanquise_update=1
	rm -f gits_bluebanquise_update
    fi
    if test -f "gits_website_update"; then
        gits_website_update=1
        rm -f gits_website_update
    fi
    if test -f "gits_infrastructure_update"; then
        gits_infrastructure_update=1
        rm -f gits_infrastructure_update
    fi

    # Check if any updates
    echo "[Gits] Starting check..."
    cd $CURRENT_DIR/gits/bluebanquise

    git remote update
    UPSTREAM=${1:-'@{u}'}
    LOCAL=$(git rev-parse @)
    REMOTE=$(git rev-parse "$UPSTREAM")
    BASE=$(git merge-base @ "$UPSTREAM")

    if [ $LOCAL = $REMOTE ]; then
        echo "[Gits] BlueBanquise Up-to-date"
    elif [ $LOCAL = $BASE ]; then
        echo "[Gits] BlueBanquise Need to pull"
        git pull
        gits_bluebanquise_update=1
    elif [ $REMOTE = $BASE ]; then
        echo "[Gits] BlueBanquise Need to push"
    else
        echo "[Gits] BlueBanquise Diverged !"
    fi

    cd $CURRENT_DIR/gits/infrastructure
    git remote update
    UPSTREAM=${1:-'@{u}'}
    LOCAL=$(git rev-parse @)
    REMOTE=$(git rev-parse "$UPSTREAM")
    BASE=$(git merge-base @ "$UPSTREAM")

    if [ $LOCAL = $REMOTE ]; then
        echo "[Gits] Infrastructure Up-to-date"
    elif [ $LOCAL = $BASE ]; then
        echo "[Gits] Infrastructure Need to pull"
        git pull
        gits_infrastructure_update=1
    elif [ $REMOTE = $BASE ]; then
        echo "[Gits] Infrastructure Need to push"
    else
        echo "[Gits] Infrastructure Diverged !"
    fi

    cd $CURRENT_DIR/gits/website
    git remote update
    UPSTREAM=${1:-'@{u}'}
    LOCAL=$(git rev-parse @)
    REMOTE=$(git rev-parse "$UPSTREAM")
    BASE=$(git merge-base @ "$UPSTREAM")

    if [ $LOCAL = $REMOTE ]; then
        echo "[Gits] Website Up-to-date"
    elif [ $LOCAL = $BASE ]; then
        echo "[Gits] Website Need to pull"
        git pull
        gits_website_update=1
    elif [ $REMOTE = $BASE ]; then
        echo "[Gits] Website Need to push"
    else
        echo "[Gits] Website Diverged !"
    fi

    cd $CURRENT_DIR
    echo "[Gits] Done."

    if [ "$gits_website_update" -eq 1 ]; then

        echo "[Website] Starting website upload"
        rm -Rf /dev/shm/website
        cp -a gits/website /dev/shm
        rm -Rf /dev/shm/website/.git
        rm -f /dev/shm/website/.gitignore
        rm -Rf /dev/shm/website/.git*
        sshpass -p "$website_pass" sftp $website_user@ftp.$website_host <<EOF
put -r /dev/shm/website/bluebanquise/* /home/$website_user/bluebanquise/
exit
EOF
        echo "[Website] Done."
        echo "[Website] Forcing main bluebanquise refresh now."
        gits_bluebanquise_update=1
    fi

    if [ "$gits_bluebanquise_update" -eq 1 ]; then

        ## MAIN DOC
        echo "[Doc] Starting documentation build"
        sudo sed -i "s|Documentation\ last\ build\ attempt:.*|Documentation last build attempt: $(date)<br>|" /var/www/html/index.html
        rm -Rf /dev/shm/documentation
        cp -a gits/bluebanquise/documentation /dev/shm
        cd /dev/shm/documentation
        make html > /tmp/doreamon_documentation_build_log 2>&1
        
        if [ $? -eq 0 ]; then
            echo "[Doc] Build success !"
            echo "[Doc] Uploading documentation"
            lftp -u $website_user,$website_pass sftp://ssh.$website_host <<EOF
rm -r /home/$website_user/bluebanquise/documentation
exit
EOF
            sshpass -p "$website_pass" sftp $website_user@ftp.$website_host <<EOF
mkdir /home/$website_user/bluebanquise/documentation
put -r /dev/shm/documentation/_build/html/* /home/$website_user/bluebanquise/documentation/
exit
EOF
            sudo sed -i 's|Documentation\ build\ status:.*|Documentation build status: <div class="green-square"></div><br>|' /var/www/html/index.html
            sudo sed -i "s|Documentation\ last\ successful\ build:.*|Documentation last successful build: $(date)<br>|" /var/www/html/index.html
        else
            echo "[Doc] Build failed !"
            sudo sed -i 's|Documentation\ build\ status:.*|Documentation build status: <div class="red-square"></div><br>|' /var/www/html/index.html
        fi
        echo "[Doc] Done."
        cd $CURRENT_DIR

        ## TUTORIALS
        echo "[Tuto] Starting tutorials build"
        sudo sed -i "s|Tutorials\ last\ build\ attempt:.*|Tutorials last build attempt: $(date)<br>|" /var/www/html/index.html
        rm -Rf /dev/shm/tutorials
        cp -a gits/bluebanquise/tutorials /dev/shm
        cd /dev/shm/tutorials
        mkdocs build > /tmp/doreamon_tutorials_build_log 2>&1

        if [ $? -eq 0 ]; then
            echo "[Tuto] Build success !"
            echo "[Tuto] Uploading Tutorials"
            lftp -u $website_user,$website_pass sftp://ssh.$website_host <<EOF
rm -r /home/$website_user/bluebanquise/tutorials
exit
EOF
            sshpass -p "$website_pass" sftp $website_user@ftp.$website_host <<EOF
mkdir /home/$website_user/bluebanquise/tutorials
put -r /dev/shm/tutorials/site/* /home/$website_user/bluebanquise/tutorials/
exit
EOF
            sudo sed -i 's|Tutorials\ build\ status:.*|Tutorials build status: <div class="green-square"></div><br>|' /var/www/html/index.html
            sudo sed -i "s|Tutorials\ last\ successful\ build:.*|Tutorials last successful build: $(date)<br>|" /var/www/html/index.html
        else
            echo "[Tuto] Build failed !"
            sudo sed -i 's|Tutorials\ build\ status:.*|Tutorials build status: <div class="red-square"></div><br>|' /var/www/html/index.html
        fi
        echo "[Tuto] Done."
        cd $CURRENT_DIR

    fi



    if [ "$gits_infrastructure_update" -eq 1 ]; then
        echo "[Repo] Starting packages build"
        sudo sed -i "s|Repositories\ last\ build\ attempt:.*|Repositories last build attempt: $(date)<br>|" /var/www/html/index.html
        sudo sed -i 's|Repositories\ build\ status:.*|Repositories build status: <div class="blue-square"></div><br>|' /var/www/html/index.html
        cd $CURRENT_DIR/gits/infrastructure/CI/
        ./engine.sh arch_list="x86_64 arm64 aarch64" os_list="el8 el9 lp15 ubuntu2004 ubuntu2204 debian11 debian12" steps="build repositories" > /tmp/doreamon_repositories_build_log 2>&1
        if [ $? -eq 0 ]; then
            echo "[Repo] Build success !"

            rm -Rf /tmp/distant-repo
            mkdir /tmp/distant-repo
            cp -a $HOME/CI/repositories/* /tmp/distant-repo/

            lftp -u $website_user,$website_pass sftp://ssh.$website_host <<EOF
rm -r /home/$website_user/bluebanquise/repository/releases/latest
exit
EOF

            sshpass -p "$website_pass" sftp $website_user@ftp.$website_host <<EOF
mkdir /home/$website_user/bluebanquise/repository/releases/latest
put -r /tmp/distant-repo/* /home/$website_user/bluebanquise/repository/releases/latest/
exit
EOF

            sudo sed -i 's|Repositories\ build\ status:.*|Repositories build status: <div class="green-square"></div><br>|' /var/www/html/index.html
            sudo sed -i "s|Repositories\ last\ successful\ build:.*|Repositories last successful build: $(date)<br>|" /var/www/html/index.html
        else
            echo "[Repo] Build failed !"
            sudo sed -i 's|Repositories\ build\ status:.*|Repositories build status: <div class="red-square"></div><br>|' /var/www/html/index.html
        fi   
        echo "[Repo] Done."
    fi
    cd $CURRENT_DIR

    echo "[ALL] Pass done, entering sleep."
    cd $CURRENT_DIR
    sleep 3600
done


