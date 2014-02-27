#!/bin/bash
: << EOF
    This script check the following items：
    1. balance != "" && balance !="*"
    2. cpr >=0 && cpr <=100
    3. wac <10

    you can use this script by this:
    ./CheckSelf WFPrepaymentArm dec
    WFPrepaymentArm is the report dir.
EOF


DIR="$1"   #the directory where the report txt file locate in
CURRM="$2"  #current month, pls do not forget this parameter.

#get the field number which the cpr and balance locate in.
function getNF()
{
    head -3 $1|grep "Balance" | awk -F"\t" -v KEY="$2" '
    {
		
        for (n=1;n<=NF;n++)
		{
			gsub(/[[:blank:]]*/, "", $(n));
			L=tolower($(n));
			if (index(L, KEY))
			{
				MAP[KEY]=n;
			}
			else if (L == "balance")
			{
				MAP["balance"]=n;
			}
		}
    }
    END {
		print MAP[KEY];
    }
    '
}

#remove the left and right blank
function dealfor()
{
    cat "$1" | awk -F"\t" -v OFS='\t' '
    {
        for (n=0;n<=NF;n++)
            {
                gsub(/[[:blank:]]*$/,"",$(n));
                gsub(/^[[:blank:]]*/,"",$(n))
                gsub(/\$/,"",$3); #remove '$' in balance, WFPrapaymentFix report balance has a '$'
                gsub(/,/,"",$3);
            }
            print $0
    }
    '
}

#file list, these file name should not change, if changed then should update this script.
aglist="fh10.txt fh15.txt fh20.txt fh30.txt fn10.txt fn15.txt fn20.txt fn30.txt g115.txt g130.txt g215.txt g230.txt fn.txt fh.txt g2.txt"

#start the check process
for FILE in $(echo "$aglist")
do
    FILE="$DIR/$FILE"
    [ ! -f $FILE ] && continue

    #deal the org file and cut the header
    var=$(grep -n "Balance" $FILE|cut -d':' -f1)
    str="sed '1,$var d'"

    #get the cpr column number
    cprnf=$(getNF "$FILE" "cpr")

    #get the balance column number
    balnf=$(getNF "$FILE" "balance")

    #get the current month column number
    currmnf=$(getNF "$FILE" "$CURRM")

    #get the wac column number
    wacnf=$(getNF "$FILE" "wac")

    #begin to deal the file and find the error
    #if there is no error then awk will output nothing or it will output the error line
    cat "$FILE" |eval $str | awk -F'\t' -v CPRNF=$cprnf -v BALNF=$balnf -v FN="$FILE" \
     -v CURRMNF="$currmnf" -v WACNF="$wacnf" -v OFS='\t' -v FD="/tmp/$(basename $FILE).self.diff" '
    {
		for(n=CURRMNF;n<CURRMNF+10;n++)
		{
			gsub(/[[:blank:]]*$/,"",$(n));
			gsub(/^[[:blank:]]*/,"",$(n));
			gsub(/%/,"",$(n));
			$(n)=sprintf("%.1f",$(n)+0.000001);
		}
		
        gsub(/[[:blank:]]*$/,"",$(BALNF));
        gsub(/^[[:blank:]]*/,"",$(BALNF))
        gsub(/\$/,"",$(BALNF));
        gsub(/,/,"",$(BALNF));
        $(BALNF)=sprintf("%.0f",$(BALNF));
		
        gsub(/[[:blank:]]*$/,"",$(CPRNF));
        gsub(/^[[:blank:]]*/,"",$(CPRNF))
		
        gsub(/[[:blank:]]*$/,"",$(1));
        gsub(/^[[:blank:]]*/,"",$(1))
		
        gsub(/[[:blank:]]*$/,"",$(2));
        gsub(/^[[:blank:]]*/,"",$(2))
		
        gsub(/[[:blank:]]*$/,"",$(WACNF));
        gsub(/^[[:blank:]]*/,"",$(WACNF))
        gsub(/%/,"",$(WACNF));
        $(WACNF)=sprintf("%.2f",$(WACNF)+0.000001);
		
        if ($1=="" && $2=="")
		{
			next;
		}
		
		#cpr must in [-100, 100]
		if ( strtonum($(CPRNF)) < -100 || strtonum($(CPRNF)) > 100)
		{
            print FN": CPR ERROR("CPRNF"#"$(CPRNF)"):===>\t"$0;
		}
		
		#balance must not null or 0
		if (strtonum($(BALNF)) == 0)
		{
            print FN": BALANCE ERROR("BALNF"#"$(BALNF)"):===>\t"$0;
		}
		
        #wac should <10
		if(strtonum($(WACNF)) >= 10)
		{
            print FN": WAC ERROR("WACNF"#"$(WACNF)"):===>\t"$0;
		}
		
        #cpr should in [0, 100]
		for (n=CURRMNF;n<=CURRMNF+10;n++)
		{
			if(strtonum($(n)) < 0 || strtonum($(n)) > 100)
			{
				print FN": MONTH CPR ERROR("n"#"$(n)"):===>\t"$0;
			}
		}
    }
    '
done


: << EOF
    Ckeck WFSpecpool & WFServicerSpecpool
    requirement:
    1. For the following specpools, refi% are hard-coded 100%: 
       CQ/CR/CV/CW/U4/U6/U7/U9
    2. CR,U9 only appears including and after 2012
    3. CK,CJ,T4,T6 only appears including and after 2008
    4. only show the following specpools if any when coupon >= 5.5 :
       TBA,LLB,MLB,MHLB,HLB,SHLB,Investor,NY,PR,TX,CQ,CR,CV,CW,U4,U6,U7,U9,CK,CJ,T4,T6
    5. remove MHA90,MHA95 appears including and after 2009
EOF

r1="CQ/CR/CV/CW/U4/U6/U7/U9 Refi% must be 100%"
r2="CR U9 should not be in year < 2012"
r3="CK,CJ,T4,T6 should not be in year < 2008"
r4="if CPN >=5.5 then pool must be in TBA,LLB,MLB,MHLB,HLB,SHLB,Investor,NY,PR,TX,CQ,CR,CV,CW,U4,U6,U7,U9,CK,CJ,T4,T6"
r5="MHA90/95/100/105 should not be in year < 2009"

for file in $(ls -1 $1/*15.txt 2>/dev/null)
do
    [ "$1" != "WFServicerSpecpool" -a "$1" != "WFSpecpool" ] && break
    sed '1,2d' $file | awk -F'\t' -v FILE="$file" -v OFS="\t" '{

    #check Specpool CR,U9
    CY=$2
    gsub(/[A-Za-z]/,"",CY);
    if(index("CR/U9", $3) && strtonum(CY) < 2012 && $2 != "All")
        {
            print FILE": "$3" ERROR("3"#"$2") ==>\t"$0
        }

    #check CK,CJ,T4,T6
    if(index("CK/CJ/T4/T6", $3) && strtonum(CY) < 2008 && $2 != "All")
        {
            print FILE": "$3" ERROR("3"#"$2") ==>\t"$0
        }

    #check CPN & Specpool
    if (strtonum($1) >=5.5 && !index("TBALLBMLBMHLBHLBSHLBInvestorNYPRTXCQCRCVCWU4U6U7U9CKCJT4T6", $3) && $3 != "Cohort")
        {
            print FILE": CPN & Specpool ERROR("$1"&"$3") ==>\t"$0
        }

    #check MHA
    if (strtonum(CY) < 2009 && index("MHA90MHA95MHA100MHA105", $3) && $2 != "All")
        {
            print FILE": YEAR & MHA ERROR("$2"&"$3") ==>\t"$0
        }

    #check Refi, Refi% must be 100%
    if(index("CQ/CR/CV/CW/U4/U6/U7/U9", $3) && $NF != 100)
        {
            print FILE": Refi ERROR("NF"#"$NF") ==>\t"$0
        }

    #check cpn
    if (!index("2.0|2.5|3.0|3.5|4.0|4.5|5.0|5.5", $1))
        {
            print FILE": CPN ERROR(1#"$1") ==>"$0
        }

    if($1 == "2.0" && !index("20132012", $2) && $2 != "All")
        {
            print FILE": YEAR ERROR(2#"$2") ==>"$0
        }
    else if($1 == "2.5" && !index("201320122011", $2) && $2 != "All")
        {
            print FILE": YEAR ERROR(2#"$2") ==>"$0
        }
    else if($1 == "3.0" && !index("2013201220112010", $2) && $2 != "All")
        {
            print FILE": YEAR ERROR(2#"$2") ==>"$0
        }
    else if($1 == "3.5" && !index("2013201220112010", $2) && $2 != "All")
        {
            print FILE": YEAR ERROR(2#"$2") ==>"$0
        }
    else if($1 == "4.0" && !index("201320122011201020092009 PRE2009 POST", $2) && $2 != "All")
        {
            print FILE": YEAR ERROR(2#"$2") ==>"$0
        }
    else if($1 == "4.5" && !index("201320122011201020092009 PRE2009 POST", $2) && $2 != "All")
        {
            print FILE": YEAR ERROR(2#"$2") ==>"$0
        }
    else if($1 == "5.0" && !index("2011201020092009 PRE2009 POST2008 ", $2) && $2 != "All")
        {
            print FILE": YEAR ERROR(2#"$2") ==>"$0
        }
    else if($1 == "5.5" && !index("20092009 PRE 2009 POST2008200720062005", $2) && $2 != "All")
        {
            print FILE": YEAR ERROR(2#"$2") ==>"$0
        }
    }'
done

#check  30yr cpn & year
for file in $(ls -1 $1/*30.txt 2>/dev/null)
do
    [ "$1" != "WFServicerSpecpool" -a "$1" != "WFSpecpool" ] && break
    sed '1,2d' $file | awk -F'\t' -v FILE="$file" -v OFS="\t" '{

    #check Specpool CR,U9
    CY=$2
    gsub(/[A-Za-z]/,"",CY);
    if(index("CR/U9", $3) && strtonum(CY) < 2012 && $2 != "All")
        {
            print FILE": "$3" ERROR("3"#"$2") ==>\t"$0
        }

    #check CK,CJ,T4,T6
    if(index("CK/CJ/T4/T6", $3) && strtonum(CY) < 2008 && $2 != "All")
        {
            print FILE": "$3" ERROR("3"#"$2") ==>\t"$0
        }

    #check CPN & Specpool
    if (strtonum($1) >=5.5 && !index("TBALLBMLBMHLBHLBSHLBInvestorNYPRTXCQCRCVCWU4U6U7U9CKCJT4T6", $3) && $3 != "Cohort")
        {
            print FILE": CPN & Specpool ERROR("$1"&"$3") ==>\t"$0
        }

    #check MHA
    if (strtonum(CY) < 2009 && index("MHA90MHA95MHA100MHA105", $3) && $2 != "All")
        {
            print FILE": YEAR & MHA ERROR("$2"&"$3") ==>\t"$0
        }

    #check Refi, Refi% must be 100%
    if(index("CQ/CR/CV/CW/U4/U6/U7/U9", $3) && $NF != 100)
        {
            print FILE": Refi ERROR("NF"#"$NF") ==>\t"$0
        }

    #check cpn
    if (!index("3.0|3.5|4.0|4.5|5.0|5.5|6.0", $1))
        {
            print FILE": CPN ERROR(1#"$1") ==>"$0
        }

    if($1 == "3.0" && !index("20132012", $2) && $2 != "All")
        {
            print FILE": YEAR ERROR(2#"$2") ==>"$0
        }
    else if($1 == "3.5" && !index("2013201220112010", $2) && $2 != "All")
        {
            print FILE": YEAR ERROR(2#"$2") ==>"$0
        }
    else if($1 == "4.0" && !index("201320122011201020092009 PRE2009 POST", $2) && $2 != "All")
        {
            print FILE": YEAR ERROR(2#"$2") ==>"$0
        }
    else if($1 == "4.5" && !index("201320122011201020092009 PRE2009 POST", $2) && $2 != "All")
        {
            print FILE": YEAR ERROR(2#"$2") ==>"$0
        }
    else if($1 == "5.0" && !index("2011201020092009 PRE2009 POST2008", $2) && $2 != "All")
        {
            print FILE": YEAR ERROR(2#"$2") ==>"$0
        }
    else if($1 == "5.5" && !index("20092009 PRE2009 POST2008200720062005", $2) && $2 != "All")
        {
            print FILE": YEAR ERROR(2#"$2") ==>"$0
        }
    else if($1 == "6.0" && !index("20092009 PRE2009 POST2008200720062005", $2) && $2 != "All")
        {
            print FILE": YEAR ERROR(2#"$2") ==>"$0
        }
    }'
done
