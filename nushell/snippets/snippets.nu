# Nushell snippets - abbreviation definitions
# Each entry maps an abbreviation to its expansion
# Use % as a placeholder for cursor jump points

def get-snippets [] {
    {
        fo: 'findOne({%})'
        pj: '| jq ".[%]"'
        fm: 'find({%})'
        uo: 'updateOne({%}, {$set: {%}})'
        um: 'updateMany({%}, {$set: {%}})'
        fn: 'def % [] { % }'
        dis: 'DistributionCenter'
        ct: 'countDocuments()'
        ho: 'HistoricalOrder'
        last: 'sort({createDate: -1}).limit(%)'
        ed: '| editor'
        dm: '| deleteMany'
        st: 'select(%)'
    }
}
