PARAM="./2Dcomp -n -k vie -i 500 -s 512 " # parametres commun à toutes les executions 
OUTPUT="results/basic.data"

echo "iteration;version;conf;grain;temps;" >> $OUTPUT
for iteration in {1..5}
do
    for version in "seq" "tuile" "tuile_opt"
    do
	for config in "guns" "random"
	do
	    for grain in 8 16 32 64
	    do
		exp=$PARAM" -g $grain -a $config -v $version"
		echo $exp
		echo -n "$iteration;$version;$config;$grain;" >> $OUTPUT
		$exp 2>> $OUTPUT
	    done
	done
    done
done
