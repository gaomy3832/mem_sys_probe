
if [ "$#" -eq 1 ] && ( [ "$1" == "-e" ] || [ "$1" == "-enable" ] ); then
    en=true
elif [ "$#" -eq 1 ] && ( [ "$1" == "-d" ] || [ "$1" == "-disable" ] ); then
    en=false
else
    echo "Usage: prefetch_ctrl.sh [-e(nable)] [-d(isable)]" >&2
    exit 1
fi

# Number of logic cores.
ncpus=`cat /proc/cpuinfo | grep "^processor" | wc -l`
let "lastcpu = ${ncpus} - 1"

sudo modprobe msr

# Test which msr to use.
# Bit 9 and 19 in msr 0x1a0 for Core and before.
# Bit 0, 1, 2, 3 in msr 0x1a4 for Nehalem and after.
# https://software.intel.com/en-us/articles/optimizing-application-performance-on-intel-coret-microarchitecture-using-hardware-implemented-prefetchers
# https://software.intel.com/en-us/articles/disclosure-of-hw-prefetcher-control-on-some-intel-processors
sudo rdmsr -p 0 0x1a4 >/dev/null 2>&1
if [ "$?" -eq 0 ]; then
    uarch_is_core=false
    msrno=0x1a4
else
    uarch_is_core=true
    msrno=0x1a0
fi
echo "Use MSR ${msrno}"

for cpu in `seq 0 ${lastcpu}`; do
    # Use -d for decimal output.
    msrval=$(sudo rdmsr -p ${cpu} -d ${msrno})
    msrvalold=${msrval}
    if ${en}; then
        if ${uarch_is_core}; then
            let "msrval &= 0xfff7fdff"
        else
            let "msrval &= 0xfffffff0"
        fi
    else
        if ${uarch_is_core}; then
            let "msrval |= 0x80200"
        else
            let "msrval |= 0xf"
        fi
    fi
    printf "[core %d] 0x%x --> 0x%x\n" ${cpu} ${msrvalold} ${msrval}
    sudo wrmsr -p ${cpu} ${msrno} ${msrval}
done

