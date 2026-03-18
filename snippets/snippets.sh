
typeset -A ABBR

ABBR[fo]='findOne({%})'
ABBR[pj]='| jq ".[%]"'
ABBR[fm]='find({%})'
ABBR[uo]='updateOne({%}, {\set: {%}})'
ABBR[um]='updateMany({%}, {\set: {%}})'
ABBR[fn]='function %(%) { % }'
ABBR[dis]='DistributionCenter'
ABBR[ct]='countDocuments()'
ABBR[ho]='HistoricalOrder'
ABBR[last]='.sort({createDate: -1}).limit(%)'
ABBR[ed]='| editor'
