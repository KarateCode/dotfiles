# Delete local git branches interactively using fzf multi-select
def gitbd [] {
    let branches = (
        git branch
        | lines
        | str trim
        | where { |b| not ($b | str starts-with "*") }
        | where { |b| $b not-in ["develop", "main", "master"] }
    )

    if ($branches | is-empty) {
        print "No branches available to delete."
        return
    }

    let selected = (
        $branches
        | to text
        | fzf --multi --header="Choose local git branches to delete"
    )

    if ($selected | is-empty) {
        print "No branches selected."
        return
    }

    $selected | lines | each { |branch|
        let trimmed = ($branch | str trim)
        if ($trimmed | is-not-empty) {
            print $"Deleting branch: ($trimmed)"
            git branch -D $trimmed
        }
    }

    null
}
