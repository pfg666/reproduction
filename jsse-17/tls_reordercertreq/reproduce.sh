readonly SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

readonly TLSATTACKER_VER="3.0b"
readonly TLSATTACKER_FULLNAME="TLS-Attacker-$TLSATTACKER_VER"
readonly TLSATTACKER_ARCH_URL="https://github.com/RUB-NDS/TLS-Attacker/archive/$TLSATTACKER_VER.tar.gz"

readonly JDK_17_ARCH_URL="https://download.java.net/java/early_access/jdk17/23/GPL/openjdk-17-ea+23_linux-x64_bin.tar.gz"
readonly JDK_17_DIR="$SCRIPT_DIR/jdk-17-EA"

readonly JSSE_PROGRAM_DIR="$SCRIPT_DIR/tls-client"

readonly KEY=rsa2048_key.pem
readonly CERT=rsa2048_cert.pem

readonly PORT=20000

# downloads and unpacks and archive
function solve_arch() {
    arch_url=$1
    target_dir=$2
    temp_dir=/tmp/`(basename $arch_url)`
    echo $temp_dir
    echo "Fetching/unpacking from $arch_url into $target_dir"
    if [[ ! -f "$temp_dir" ]]
    then
        echo "Downloading archive from url to $temp_dir"
        wget -nc --no-check-certificate $arch_url -O $temp_dir
    fi
    
    mkdir $target_dir
    # ${temp_dir##*.} retrieves the substring between the last index of . and the end of $temp_dir
    arch=`echo "${temp_dir##*.}"`
    if [[ $arch == "xz" ]]
    then
        tar_param="-xJf"
    else 
        tar_param="zxvf"
    fi
    echo $tar_param
    if [ $target_dir ] ; then
        tar $tar_param $temp_dir -C $target_dir --strip-components=1
    else 
        tar $tar_param $temp_dir
    fi
}

# downloads and builds TLS-Attacker
function setup_tlsattacker() {
    if [[ ! -d $TLSATTACKER_FULLNAME ]]
    then
        solve_arch $TLSATTACKER_ARCH_URL $TLSATTACKER_FULLNAME
        ( cd $TLSATTACKER_FULLNAME; mvn install -DskipTests )
    fi
}

# sets up simple TLS program
function setup_jsse_program() {
    if [[ ! -d $JDK_17_DIR ]]
    then 
        solve_arch $JDK_17_ARCH_URL $JDK_17_DIR 
    fi

    $JDK_17_DIR/bin/javac -s $JSSE_PROGRAM_DIR/bin/ $JSSE_PROGRAM_DIR/src/SSLSocketClientWithClientAuth.java
}



# sets up the JDK and the test program
setup_jsse_program

# sets up TLS-Attacker
setup_tlsattacker

# execute invalid sequence of inputs using TLS-Attacker
( java -jar $TLSATTACKER_FULLNAME/apps/TLS-Server.jar -port $PORT -version TLS12 -workflow_input workflow.xml -config tlsattacker.config ) &
fuzzer_pid=$!

sleep 3

# launch JSSE program
( $JDK_17_DIR/bin/java -cp $JSSE_PROGRAM_DIR/bin/ SSLSocketClientWithClientAuth localhost 20000 rsa2048.jks student ) &
sut_pid=$!

wait $fuzzer_pid