#!/bin/bash

#./CheckOther.sh WFServicerFix

DIR="$1"


function FormatFile()
{
    local FileName="$1"

    #combine the key field and add to the first
    cat "$1" |awk -F'\t' -v OFS="\t" '
    {
        for(n = 1; n <= NF; n++)
            {
                gsub(/^[[:blank:]]*/,"",$(n));
                gsub(/[[:blank:]]*$/,"",$(n));
                gsub(/\$/,"",$(n));
                gsub(/,/,"",$(n));
                gsub(/%/,"",$(n));
                $(n)=($(n)==""?$(n):toupper($(n)));
            }
            print $0
        }
        '
}

#check Servicer g2 shuld not include Multiple Servicer.
[ "$DIR" == "WFServicerFix" -o "$DIR" == "WFServicerArm" ] && {
for f in $(ls $DIR/g2*.txt 2>/dev/null)
do
    f=$(basename $f)
    cat $DIR/$f | awk -F'\t' -v F="$DIR/$f" -v OFS='\t' '{gsub(/[[:blank:]]*/,"",$3);if(index($3, "Multiple")){print F,$1,$2,$3"ERROR ==> servicer g2 should not have Multiple"}}'
done
}

#check WFServicerSpecpool & WFSpecpool shuld always include "TBA" specpool.
[ "$DIR" == "WFServicerSpecpool" -a "$DIR" == "WFSpecpool" ] && {
for f in $(ls $DIR/*.txt)
do
    f=$(basename $f)

    #get key
    cat $DIR/$f |awk -F'\t' '{
    gsub(/[[:blank:]]*/,"",$1);
    gsub(/[[:blank:]]*/,"",$2);
    gsub(/[[:blank:]]*/,"",$3);
    if (!match($1,/[0-9]/))
        {
            next;
        }

        if ($3!="TBA")
            {
                print $1"\t"$2"\t"$3
            }
        }' | sed '/^$/d'|sort|uniq > /tmp/key.txt

        >/tmp/tba.txt
        while read key
        do
            f1=$(echo "$key"|awk -F'\t' '{print $1}')
            f2=$(echo "$key"|awk -F'\t' '{print $2}')
            f3=$(echo "$key"|awk -F'\t' '{print $3}')

            cat $DIR/$f |awk -F'\t' -v F1="$f1" -v F2="$f2" -v F3="$f3" -v F="$DIR/$f" '
            BEGIN {
            flag=0
        }
        {
            gsub(/[[:blank:]]*/,"",$1);
            gsub(/[[:blank:]]*/,"",$2);
            if(F1==$1 && F2==$2 && $3=="TBA")
                {
                    flag=1;
                }
            }
            END {
            if(flag==0)
                {
                    print F"\t"F1"\t"F2"\t"F3
                }
            }
            ' |sed '/^$/d' >> /tmp/tba.txt
        done < /tmp/key.txt
        [ "$(cat /tmp/key.txt|wc -l)" != "$(cat /tmp/tba.txt|wc -l)" ] && cat /tmp/tba.txt
    done
}


#check with the last month, balance shuld not be equal.
for F in $(ls $DIR/*.txt)
do
    F=$(basename $F)

    #deal curr month file
    [ $(cat $DIR/$F|wc -l) -le $(cat LastMonth/$DIR/$F|wc -l) ] && echo -e "\033[31m$DIR/$F ERROR ==> current month total lines should greater than last month,pls check($(cat $DIR/$F|wc -l) <= $(cat LastMonth/$DIR/$F|wc -l))\033[0m"

    FormatFile $DIR/$F > /tmp/FormatFile.txt
    FormatFile LastMonth/$DIR/$F > /tmp/LastMonthFormatFile.txt

    if [ "$DIR" == "WFServicerSpecpool" ];then
        flag="SS"
    elif [ "$DIR" == "WFSpecpool" ];then
        flag="S"
    elif [ "$DIR" == "WFServicerArm" -o "$DIR" == "WFServicerFix" ];then
        flag="SE"
    fi

    while read line
    do
        f1=$(echo "$line"|awk -F'\t' '{print $1}')
        f2=$(echo "$line"|awk -F'\t' '{print $2}')
        f3=$(echo "$line"|awk -F'\t' '{print $3}')
        f4=$(echo "$line"|awk -F'\t' '{print $4}')
        f5=$(echo "$line"|awk -F'\t' '{print $5}')

        cat /tmp/LastMonthFormatFile.txt |awk -F'\t' -v F1="$f1" -v F2="$f2" -v F3="$f3" \
            -v F4="$f4" -v F5="$f5" -v FN="$DIR/$F" -v FLAG="$flag" '{
        if (index($0, "BALANCE") || index($0, "CURRENT"))
            {
                next;
            }
        if (FLAG=="S" || FLAG == "SE")
            {
                if ($1 == F1 && $2==F2 && $3==F3 && $4==F4)
                    {
                        print "ERROR: balance should not be equal ==>"FN,$1,$2,$3,$4;
                    }
            }
        else if (FLAG == "SS")
            {
                if ($1 == F1 && $2==F2 && $3==F3 && $4==F4 && $5 == F5)
                    {
                        print "ERROR: balance should not be equal ==>"FN,$1,$2,$3,$4,$5;
                    }
                }
            else
                {
                    if ($1 == F1 && $2==F2 && $3 == F3)
                        {
                            print "ERROR: balance should not be equal ==>"FN,$1,$2,$3;
                        }
                }
        }'
    done < /tmp/FormatFile.txt
done
