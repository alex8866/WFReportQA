#!/bin/bash

: << EOF
you can use this script by this:
./CheckLike.sh WFPrepaymentArm WFServicerArm dec
EOF


#get the report calss.
JUG=$(echo $1$2|awk '{if(index($0, "WFServicerSpecpool") && index($0, "WFSpecpool")){print "1"}}')
F1=
F2=
ALLLOG=/tmp/all.log
MM="$3" #lobal variables

#insure the value of PDIR is */WFPrepayment* or */WFSpecpool, because need to deal the files in these dirs and the method is different
if [ "$(echo $1|awk -v jug="$JUG" '{if(index($0, "Prepayment") || (jug=="1" && index($0, "WFSpecpool"))){print "1"}}')" == "1" ];then
    PDIR="$1"
    SDIR="$2"
else
    PDIR="$2"
    SDIR="$1"
fi

#the list of files in WFPrepaymentFix WFServicerArm WFServicerFix WFSpecpool WFServicerSpecpool
aglist="fh10.txt fh15.txt fh20.txt fh30.txt fn10.txt fn15.txt fn20.txt fn30.txt g115.txt g130.txt g215.txt g230.txt fn.txt fh.txt g2.txt"

c=$(echo $SDIR| awk '
{
    if(index($0, "Fix"))
        {
            print "Fix";
        }
    else if (index($0, "Arm"))
       {
           print "Arm";
       }
   else if (index($0, "WFServicerSpecpool"))
       {
        print "ServicerSpecpool";
       }
   else if (index($0,"WFSpecpool"))
       {
        print "Specpool";
       }
}
'
)

#get the column number
function getNF()
{
    head -3 $1|grep "Balance" | awk -F"\t" -v KEY="$2" -v CURM="$MM" '
    {
        for (n=1;n<=NF;n++)
            {
                gsub(/[[:blank:]]*/, "", $(n));
                L=tolower($(n));
                if (L == "cpr")
                    {
                        MAP["cpr"]=n;
                    }
                else if (L == "balance")
                    {
                        MAP["balance"]=n;
                    }
                else if (L == "wac")
                    {
                        MAP["wac"]=n;
                    }
                else if (L == "wala")
                    {
                        MAP["wala"]=n;
                    }
                else if (L == "aols")
                    {
                        MAP["aols"]=n;
                    }
                else if (L == "cltv")
                    {
                        MAP["cltv"]=n;
                    }
                else if (L == "fico")
                    {
                        MAP["fico"]=n;
                    }
                else if (index(L,"refi"))
                    {
                        MAP["refi"]=n;
                    }
                else if (index(L,CURM))
                    {
                        MAP[CURM]=n;
                    }
            }

        }
        END {
            print MAP[KEY];
        }
        '

}


#deal the file, change the layout.
function dealfile()
{
    local FILE="$1"  #file name 
    local str="$2"   #sed str
    local cprnf="$3" #cpr column number in the org file
    local balnf="$4" #balance column number in the org file
    local ps="$5"    #Suffix
    local ex="$6"    #flag

    wacnf=$7
    walanf=$8
    aolsnf=$9
    cltvnf=${10}
    ficonf=${11}
    refinf=${12}
    mf=${13}

    cat "$FILE" | eval $str| awk -F"\t" -v CPRNF=$cprnf -v BALNF=$balnf -v C="$c" -v PS="$ps" -v PPS="$ex" \
        -v WACNF=$wacnf -v WALANF=$walanf -v AOLSNF=$aolsnf -v CLTVNF=$cltvnf -v FICONF=$ficonf -v REFINF=$refinf \
        -v MF="$mf" -v OFS='\t' '{
		for(n=1;n<=11;n++)
		{
			gsub(/[[:blank:]]*$/,"",$(MF+n-1));
			gsub(/^[[:blank:]]*/,"",$(MF+n-1));
			gsub(/\$/,"",$(MF+n-1));
			gsub(/,/,"",$(MF+n-1));
			$(MF+n-1) = sprintf("%.1f",$(MF+n-1)+0.000001);
		}
		
        # remove the left and right blank
        gsub(/[[:blank:]]*$/,"",$(BALNF));
        gsub(/^[[:blank:]]*/,"",$(BALNF))
        gsub(/\$/,"",$(BALNF));
        gsub(/,/,"",$(BALNF));
		
        gsub(/[[:blank:]]*$/,"",$(CPRNF));
        gsub(/^[[:blank:]]*/,"",$(CPRNF))

        gsub(/[[:blank:]]*$/,"",$(WACNF));
        gsub(/^[[:blank:]]*/,"",$(WACNF))

        gsub(/[[:blank:]]*$/,"",$(WALANF));
        gsub(/^[[:blank:]]*/,"",$(WALANF))

        gsub(/[[:blank:]]*$/,"",$(AOLSNF));
        gsub(/^[[:blank:]]*/,"",$(AOLSNF))
        gsub(/,/,"",$(AOLSNF));

        gsub(/[[:blank:]]*$/,"",$(CLTVNF));
        gsub(/^[[:blank:]]*/,"",$(CLTVNF))

        gsub(/[[:blank:]]*$/,"",$(FICONF));
        gsub(/^[[:blank:]]*/,"",$(FICONF))
        gsub(/[[:blank:]]*$/,"",$(FICONF+1));
        gsub(/^[[:blank:]]*/,"",$(FICONF+1))

        gsub(/[[:blank:]]*$/,"",$(REFINF));
        gsub(/^[[:blank:]]*/,"",$(REFINF))

        gsub(/[[:blank:]]*$/,"",$(1));
        gsub(/^[[:blank:]]*/,"",$(1))

        gsub(/[[:blank:]]*$/,"",$(2));
        gsub(/^[[:blank:]]*/,"",$(2))

        gsub(/[[:blank:]]*$/,"",$(3));
        gsub(/^[[:blank:]]*/,"",$(3))

        #if blank line then next
        if ($1=="" && $2=="" && $(CPRNF)=="" && $(BALNF)=="" && $3=="")
		{
			next;
		}
		
		#change accuracy: balance = %.0f and cpr = %.2f
        $(BALNF)=sprintf("%.0f",$(BALNF)+0.000001);
        $(CPRNF)=sprintf("%.2f",$(CPRNF)+0.000001);
		
        # if $2==tba then next, tba line is no needed
        if (tolower($2)=="tba")
		{
			#next;
		}
		
		#chang "All"  to "all"
		if (tolower($2)=="all")
		{
                $2="all";
		}
		
		#choose the "all" line ,this line the two files should be equal
		if ((PS=="s" && tolower($3) !="all") || (PS=="sp" && tolower($3) != "cohort" && PPS=="") || (PS=="ssp" && tolower($4) != "all"))
		{
			next;
        }

		ZE=$1;
		gsub(/[0-9.]/,"",ZE);
		#if ((C=="Fix"||C=="Specpool") && tolower($1) != "all")
		if (ZE == "")
		{
			$1=sprintf("%.2f",$1+0.000001);
		}
		
		
		gsub(/%/,"",$(WACNF));
		$(WACNF) = strtonum(sprintf("%.2f",$(WACNF)+0.000001));
		$(WALANF) = strtonum(sprintf("%.0f",$(WALANF)+0.000001));
		$(AOLSNF) = strtonum(sprintf("%.0f",$(AOLSNF)+0.000001));
		$(CLTVNF) = strtonum(sprintf("%.0f",$(CLTVNF)+0.000001));
		$(FICONF) = strtonum(sprintf("%.0f",$(FICONF)+0.000001));
		$(FICONF+1) = strtonum(sprintf("%.0f",$(FICONF+1)+0.000001));
		gsub(/%/,"",$(REFINF));
		$(REFINF) = strtonum(sprintf("%.0f",$(REFINF)+0.000001));

		if (PPS != "")
		{
			print $1,$2,$3,$(BALNF),$(CPRNF),$(MF),$(MF+1),$(MF+2),$(MF+3),$(MF+4),$(MF+5),$(MF+6),$(MF+7),$(MF+8),$(MF+9),$(MF+10),$(WACNF),$(WALANF),$(AOLSNF),$(CLTVNF),$(FICONF),$(FICONF+1),$(REFINF);
		}
		else
		{
			print $1,$2,$(BALNF),$(CPRNF),$(MF),$(MF+1),$(MF+2),$(MF+3),$(MF+4),$(MF+5),$(MF+6),$(MF+7),$(MF+8),$(MF+9),$(MF+10),$(WACNF),$(WALANF),$(AOLSNF),$(CLTVNF),$(FICONF),$(FICONF+1),$(REFINF);
		}
    }' > /tmp/${ag}.$ps
}

#find the different between the two dealed files
function fd()
{
    PFILE="$1"
    SFILE="$2"
    
    > "/tmp/$(basename $PFILE).diff" 
    > "/tmp/$(basename $SFILE).diff"
    while read line
    do
       f1=$(echo "$line" |awk -F'\t' '{print $1}')
       f2=$(echo "$line" |awk -F'\t' '{print $2}')
       f3=$(echo "$line" |awk -F'\t' '{print $3}')
       f4=$(echo "$line" |awk -F'\t' '{print $4}')

       f5=$(echo "$line" |awk -F'\t' '{print $5}')
       f6=$(echo "$line" |awk -F'\t' '{print $6}')
       f7=$(echo "$line" |awk -F'\t' '{print $7}')
       f8=$(echo "$line" |awk -F'\t' '{print $8}')
       f9=$(echo "$line" |awk -F'\t' '{print $9}')
       f10=$(echo "$line" |awk -F'\t' '{print $10}')

       f11=$(echo "$line" |awk -F'\t' '{print $11}')
       f12=$(echo "$line" |awk -F'\t' '{print $12}')
       f13=$(echo "$line" |awk -F'\t' '{print $13}')
       f14=$(echo "$line" |awk -F'\t' '{print $14}')
       f15=$(echo "$line" |awk -F'\t' '{print $15}')
       f16=$(echo "$line" |awk -F'\t' '{print $16}')
       f17=$(echo "$line" |awk -F'\t' '{print $17}')
       f18=$(echo "$line" |awk -F'\t' '{print $18}')
       f19=$(echo "$line" |awk -F'\t' '{print $19}')
       f20=$(echo "$line" |awk -F'\t' '{print $20}')
       f21=$(echo "$line" |awk -F'\t' '{print $21}')
       f22=$(echo "$line" |awk -F'\t' '{print $22}')

       cat $SFILE | awk -F'\t' -v F1="$f1" -v F2="$f2" -v F3="$f3" -v F4="$f4" -v PD="/tmp/$(basename $PFILE).diff" \
           -v SD="/tmp/$(basename $SFILE).diff" -v F5="$f5" -v F6="$f6" -v F7="$f7" -v F8="$f8" \
           -v F9="$f9" -v F10="$f10" -v F11="$f11" -v F12="$f12" -v F13="$f13" -v F14="$f14" -v F15="$f15" \
           -v F16="$f16" -v F17="$f17" -v F18="$f18" -v F19="$f19" -v F20="$f20" -v F21="$f21" -v F22="$f22" -v OFS='\t' '
       {
           #print $1"\t"F1
		   if ($1 == F1 && $2 == F2)
		   {
               #the same key shuld have the same value, if not then print the error line.
               #if (strtonum($3) != strtonum(F3) || strtonum($4) != strtonum(F4))
			   if (strtonum($3) != strtonum(F3)||strtonum($4) != strtonum(F4)||strtonum($5) != strtonum(F5)||strtonum($6) != strtonum(F6)||strtonum($7) != strtonum(F7)||strtonum($8) != strtonum(F8)||strtonum($9) != strtonum(F9)||strtonum($10) != strtonum(F10)||strtonum($11) != strtonum(F11)||strtonum($12) != strtonum(F12)||strtonum($13) != strtonum(F13)||strtonum($14) != strtonum(F14)||strtonum($15) != strtonum(F15)||strtonum($16) != strtonum(F16)||strtonum($17) != strtonum(F17)||strtonum($18) != strtonum(F18)||strtonum($19) != strtonum(F19)||strtonum($20) != strtonum(F20)||strtonum($21) != strtonum(F21)||strtonum($22) != strtonum(F22))
			   {
				   print $0
				   print $0 >> SD
				   print F1,F2,F3,F4,F5,F6,F7,F8,F9,F10,F11,F12,F13,F14,F15,F16,F17,F18,F19,F20,F21,F22 >> PD
			   }
		   }
       }
       ' 
	   done < $PFILE   #compare the value line by line.
	   
   [ -s /tmp/$(basename $PFILE).diff ] && {
   echo "###########################################################" >> $ALLLOG
   echo "diff $F1  $F2" >> $ALLLOG
   echo "###########################################################" >> $ALLLOG
   diff /tmp/$(basename $PFILE).diff /tmp/$(basename $SFILE).diff >> $ALLLOG
   }
}

function sfd()
{
    PFILE="$1"
    SFILE="$2"

    > "/tmp/$(basename $PFILE).diff" 
    > "/tmp/$(basename $SFILE).diff"
    while read line
    do
       f1=$(echo "$line" |awk -F'\t' '{print $1}')
       f2=$(echo "$line" |awk -F'\t' '{print $2}')
       f3=$(echo "$line" |awk -F'\t' '{print $3}')
       f4=$(echo "$line" |awk -F'\t' '{print $4}')
       f5=$(echo "$line" |awk -F'\t' '{print $5}')

       f6=$(echo "$line" |awk -F'\t' '{print $6}')
       f7=$(echo "$line" |awk -F'\t' '{print $7}')
       f8=$(echo "$line" |awk -F'\t' '{print $8}')
       f9=$(echo "$line" |awk -F'\t' '{print $9}')
       f10=$(echo "$line" |awk -F'\t' '{print $10}')
       f11=$(echo "$line" |awk -F'\t' '{print $11}')

       f12=$(echo "$line" |awk -F'\t' '{print $12}')
       f13=$(echo "$line" |awk -F'\t' '{print $13}')
       f14=$(echo "$line" |awk -F'\t' '{print $14}')
       f15=$(echo "$line" |awk -F'\t' '{print $15}')
       f16=$(echo "$line" |awk -F'\t' '{print $16}')
       f17=$(echo "$line" |awk -F'\t' '{print $17}')
       f18=$(echo "$line" |awk -F'\t' '{print $18}')
       f19=$(echo "$line" |awk -F'\t' '{print $19}')
       f20=$(echo "$line" |awk -F'\t' '{print $20}')
       f21=$(echo "$line" |awk -F'\t' '{print $21}')
       f22=$(echo "$line" |awk -F'\t' '{print $22}')
       f23=$(echo "$line" |awk -F'\t' '{print $23}')

       cat $PFILE | awk -F'\t' -v F1="$f1" -v F2="$f2" -v F3="$f3" -v F4="$f4" -v F5="$f5" -v PD="/tmp/$(basename $PFILE).diff" \
           -v SD="/tmp/$(basename $SFILE).diff" -v F6="$f6" -v F7="$f7" -v F8="$f8" -v F9="$f9" -v F10="$f10" \
           -v F11="$f11" -v F12="$f12" -v F13="$f13" -v F14="$f14" -v F15="$f15" \
           -v F16="$f16" -v F17="$f17" -v F18="$f18" -v F19="$f19" -v F20="$f20" -v F21="$f21" -v F22="$f22" -v F23="$f23" \
           -v OFS='\t' '
       {
		   if ($1 == F1 && $2 == F2 && $3 == F3)
		   {
			   #if (strtonum($4) != strtonum(F4) || strtonum($5) != strtonum(F5))
			   if (strtonum($4) != strtonum(F4) || strtonum($5) != strtonum(F5)||strtonum($6) != strtonum(F6)||strtonum($7) != strtonum(F7)||strtonum($8) != strtonum(F8)||strtonum($9) != strtonum(F9)||strtonum($10) != strtonum(F10)||strtonum($11) != strtonum(F11)||strtonum($12) != strtonum(F12)||strtonum($13) != strtonum(F13)||strtonum($14) != strtonum(F14)||strtonum($15) != strtonum(F15)||strtonum($16) != strtonum(F16)||strtonum($17) != strtonum(F17)||strtonum($18) != strtonum(F18)||strtonum($19) != strtonum(F19)||strtonum($20) != strtonum(F20)||strtonum($21) != strtonum(F21)||strtonum($22) != strtonum(F22)||strtonum($23) != strtonum(F23))
			   {
				   print $0
				   print $0 >> PD
				   print F1,F2,F3,F4,F5,F6,F7,F8,F9,F10,F11,F12,F13,F14,F15,F16,F17,F18,F19,F20,F21,F22,F23 >> SD
			   }
		   }
       }
       ' 
   done < $SFILE

   [ -s /tmp/$(basename $PFILE).diff ] && {
   echo "###########################################################" >> $ALLLOG
   echo "diff $F1  $F2" >> $ALLLOG
   echo "###########################################################" >> $ALLLOG
   diff /tmp/$(basename $PFILE).diff /tmp/$(basename $SFILE).diff >> $ALLLOG
   }
}

#start to compare the files in the $PDIR and $SDIR
for ag in $(echo $aglist)
do
	if [ ! -f $SDIR/$ag ];then
        continue
    fi

    #deal WFPrepaymentArm, the file name in */WFPrepaymentArm is: fnarm.txt fharm.txt g2arm.txt
    if [ "$c" == "Arm" ];then
        FILE=$PDIR/${ag:0:2}arm.txt
    else
        FILE=$PDIR/$ag
    fi

    F1="$FILE"

    balnf=$(getNF "$FILE" "balance")
    cprnf=$(getNF "$FILE" "cpr")
    wacnf=$(getNF "$FILE" "wac")
    walanf=$(getNF "$FILE" "wala")
    aolsnf=$(getNF "$FILE" "aols")
    cltvnf=$(getNF "$FILE" "cltv")
    ficonf=$(getNF "$FILE" "fico")
    refinf=$(getNF "$FILE" "refi")
    mf=$(getNF "$FILE" "$MM")

    var=$(grep -n "Balance" $FILE|cut -d':' -f1)
    str="sed '1,$var d'"

    #deal WFPrepayment* or WFSpecpool report
    if [ "$JUG" != "1" ];then
        dealfile "$FILE" "$str" "$cprnf" "$balnf" "p" "" "$wacnf" "$walanf" "$aolsnf" "$cltvnf" "$ficonf" "$refinf" "$mf"
    else
        dealfile "$FILE" "$str" "$cprnf" "$balnf" "sp" "1" "$wacnf" "$walanf" "$aolsnf" "$cltvnf" "$ficonf" "$refinf" "$mf"
    fi

    #deal servicer or servicer specpool report
    OLDFILE=$FILE
    FILE=$SDIR/$ag
    
    F2="$FILE"
    balnf=$(getNF "$FILE" "balance")
    cprnf=$(getNF "$FILE" "cpr")
    wacnf=$(getNF "$FILE" "wac")
    walanf=$(getNF "$FILE" "wala")
    aolsnf=$(getNF "$FILE" "aols")
    cltvnf=$(getNF "$FILE" "cltv")
    ficonf=$(getNF "$FILE" "fico")
    refinf=$(getNF "$FILE" "refi")
    mf=$(getNF "$FILE" "$MM")

    var=$(grep -n "Balance" $FILE|cut -d':' -f1)
    str="sed '1,$var d'"

    P=$(
        if [ $c == "Specpool" ];then
            echo "sp"
        elif [ "$c" == "ServicerSpecpool" ];then
            echo "ssp"
        else
            echo "s"
        fi
    )

    if [ "$JUG" != "1" ];then
        dealfile "$FILE" "$str" "$cprnf" "$balnf" $P "" "$wacnf" "$walanf" "$aolsnf" "$cltvnf" "$ficonf" "$refinf" "$mf"

    else
        dealfile "$FILE" "$str" "$cprnf" "$balnf" $P "1" "$wacnf" "$walanf" "$aolsnf" "$cltvnf" "$ficonf" "$refinf" "$mf"
    fi

    if [ "$JUG" != "1" ];then
        var=$(fd /tmp/${ag}.p /tmp/${ag}.$P |wc -l)
        FF1=/tmp/${ag}.p.diff
        FF2=/tmp/${ag}.$P.diff
    else
        var=$(sfd /tmp/${ag}.sp /tmp/${ag}.$P |wc -l)
        FF1=/tmp/${ag}.sp.diff
        FF2=/tmp/${ag}.$P.diff
    fi
    #output the compare result
    if [ $var != "0" ];then
        B1=$(basename $OLDFILE)
        B2=$(basename $FILE)
        echo -e "\033[31m$OLDFILE have different with $FILE \033[0m" "(vimdiff $FF1 $FF2)"
    else
        echo "It's OK between $OLDFILE and $FILE"
    fi
done
