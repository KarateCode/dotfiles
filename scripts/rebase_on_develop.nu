
# rebase on develop by EP number
def rebased [ep_number: string] {
    git checkout develop
    git pull origin develop
    bash ~/dotfiles/scripts/checkout_feature.sh $ep_number

    try {
        git rebase develop
        npm run test:concurrent

        let confirm = (input "Would you like me to force push this for you? [Y/n]: ")
        if $confirm == "" or $confirm == "y" or $confirm == "Y" {
            git push origin (git symbolic-ref --short HEAD) --force
        } else {
            print "Skipping force push."
        }
    } catch {
        print "Rebase failed! You have conflicts to resolve."
        git status
    }
}
