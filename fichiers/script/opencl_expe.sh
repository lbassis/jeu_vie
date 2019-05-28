PARAM="./2Dcomp -n -k vie -v ocl -i 500 " # parametres commun à toutes les executions 
OUTPUT="results/opencl_global.data"

echo "iteration;version;taille;conf;grain;temps;" >> $OUTPUT
for iteration in {1..5}
do
    for size in 512 1024 2048 4096
    do
	for config in "guns" "random"
	do
	    for grain in 8 16 32 64
	    do
		exp=$PARAM" -g $grain -a $config -s $size"
		echo $exp
		echo -n "$iteration;global;$size;$config;$grain;" >> $OUTPUT
		$exp 2>> $OUTPUT
	    done
	done
    done
done
