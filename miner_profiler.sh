#!/bin/bash
##############################################################################
# miner_profiler.sh - Ver 1.0.0 - Copyright (C) by WormFood, 27 Mar 2014     #
#                                                                            #
# The function of this program, is to run your GPU at various settings, and  #
# record the output of bfgminer, so that you can compare different settings  #
# to determine the best settings for your GPUs.                              #
#                                                                            #
##############################################################################
#                                                                            #
#      ,           ,   This program is free software: you can redistribute   #
#     /             \   it and/or  modify it  under the  terms of  the GNU   #
#    ((__-^^-,-^^-__))   General Public  License as  published by the Free   #
#     `-_---' `---_-'   Software  Foundation,  either  version  3  of  the   #
#      `--|o` 'o|--'   License,  or  (at  your option) any  later version.   #
#         \  `  /                                                            #
#          ): :(   This program is  distributed in the  hope that it  will   #
#          :o_o:   be useful,  but WITHOUT ANY WARRANTY; without  even the   #
#           "-"   implied  warranty  of MERCHANTABILITY  or FITNESS  FOR A   #
#                PARTICULAR PURPOSE.   See the GNU General  Public License   #
#    for more details.                                                       #
#                                                                            #
#   You should have received a copy of the GNU General Public License        #
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.    #
#                                                                            #
##############################################################################
#                                                                            #
# Command line options are as follows:                                       #
# -i --intensity <start> [<stop> [<step> [<default>]]]                       #
# -t --thread-concurrency <start> [<stop> [<step> [<default>]]]              #
# -e --engine <start> [<stop> [<step> [<default>]]]                          #
# -m --memory <start> [<stop> [<step> [<default>]]]                          #
# -o --options <options to pass to the miner> (NOTE: MUST be last option     #
# -c --config <config> path to configuration file to use for default values  #
# -n --no-execute do a dry run, and don't actually execute anything          #
# -l --limit <OCL card #> limit testing to a single card                     #
# -h --help                                                                  #
# -M --minutes <runtime> how many minutes to run each test for               #
# -g --gpu-count <gpu count> 0=autodetect number of GPUs to test             #
# -E --miner-exe <bfgminer> path to bfgminer executable                      #
# -a --after-test-config <config> path to configuration file to use, after   #
#                         all tests are complete. (don't want that GPU idle) #
# -u --underclock allow underclocked tests (where memory < engine)           #
# -v --verbose use multiple times to increase the number of messages         #
# -d --dry-run dont do anything, just show what would have been done         #
# -s --skip-sanity-tests not implemented, but planned for in a future release#
#                                                                            #
# start = setting to start at                                                #
# stop = setting to stop at                                                  #
# step = step size                                                           #
# default = settings to use, when the number of tests to not exactly match   #
#           the number of GPUs. For example, if you have 3 GPUs, and you     #
#           4 tests, then the default will be used for the other 2 cards,    #
#           that are not part of the test. This option will NEVER be used    #
#           if you have only one GPU.                                        #
#                                                                            #
# debug 1-3 user informational messages 4-6 extra information 7-9 debug info #
# 0 - none. no extra messages                                                #
# 1 - basic useful informational messages                                    #
# 2 - little bit more information                                            #
# 3 - few users would find this info useful, but still for users             #
# 4 -                                                                        #
# 5 -                                                                        #
# 6 -                                                                        #
# 7 - option processing                                                      #
# 8 -                                                                        #
# 9 - every little thing is printed out                                      #
#                                                                            #
##############################################################################

function main ()
{
  # set default values. Edit as you see fit.
  
  default_miner_opts="-T --per-device-stats"; # the -T option is for text mode only (no ncurses)
  run_time=20; # default to running each test for 20-21 minutes
  gpu_count=0; # set to autodetect
  debug=0;
  i_start=0;i_stop=0;i_step=1;i_def=0;
  t_start=0;t_stop=0;t_step=1;t_def=0;
  e_start=0;e_stop=0;e_step=1;e_def=0;
  m_start=0;m_stop=0;m_step=1;m_def=0;
  #  miner_exe="bfgminer";
  #  miner_config_file="~/.bfgminer/bfgminer.conf";
  # calc_
  
  #########################################
  # PROCESS ALL COMMAND LINE OPTIONS LOOP #
  #########################################
  while [[ $# -gt 0 ]]; do
    debug 7 "Processing next option = ${1}, and there are $# parms total right now";
    debug 7 "all parms = $*";
    
    case $1 in
      --intensity|-i)
        process_opts i $*
        shift $((${num_count}+1))
        debug 7 "retrieve options i_start = $i_start, i_stop = $i_stop, i_step = $i_step, i_def = $i_def";
      ;;
      --thread-concurrency|-t)
        process_opts t $*
        shift $((${num_count}+1))
        debug 7 "retrieve options t_start = $t_start, t_stop = $t_stop, t_step = $t_step, t_def = $t_def";
      ;;
      --engine|-e)
        process_opts e $*
        shift $((${num_count}+1))
        debug 7 "retrieve options e_start = $e_start, e_stop = $e_stop, e_step = $e_step, e_def = $e_def num_count = $num_count";
      ;;
      --memory|-m)
        process_opts m $*
        shift $((${num_count}+1))
        debug 7 "retrieve options m_start = $m_start, m_stop = $m_stop, m_step = $m_step, m_def = $m_def";
      ;;
      --limit|-l)
        debug 9 "Processing -l option\n";
        shift 1;
        if ! count_arg_nums 1 $*; then # we're expecting only 1 number
          error "The -l/--limit option requires one argument, the OCL number of the card you want to limit tests to.\n"
        fi
        limit=$1;
        shift 1;
        ;;
      --minutes|-M)
        shift 1; # remove the option from the list
        if ! count_arg_nums 1 $*; then # we're expecting only 1 number
          error "The -M/--minutes option requires one argument, in minutes.\n"
        fi
        run_time=$1;
        shift 1;
        debug 2 "run_time = $run_time minutes";
      ;;
      --gpu-count|-g) # calculate the number of GPUs if given 0
        shift 1; # remove the -g/--gpu-count option
        if ! count_arg_nums 1 $*; then # we're expecting only 1 number
          error "The -g/--gpu-count option requires one argument\n"
        else
          debug 7 "isnum gpu-count returned $num_count";
        fi
        gpu_count=$1;
        shift 1;
        debug 2 "gpu-count = $gpu_count";
      ;;
      --miner-exe|-E)
        if [[ $# -le 1 ]]; then # make sure they actually passed us an argument
          error "the --miner-exe/-E option needs the path to the miner executable\n";
        fi
        # we check this later on, to make sure it is valid, in case the user does not use this option, it can use the default
        miner_exe=$2;
        shift 2;
      ;;
      --config|-c) # read the config file, and make sure it's readable
        if [[ $# -le 1 ]]; then # make sure they actually passed us an argument
          error "the --config/-c option needs the path to a config file\n";
        fi
        miner_config_file=$2;
        if ! [ -r $miner_config_file ]; then
          error "config file $miner_config_file not found\n";
        else
          debug 2 "config file = $miner_config_file";
        fi
        shift 2;
      ;;
      --after-test-config|-a) # read the config file, and make sure it's readable
        if [[ $# -le 1 ]]; then # make sure they actually passed us an argument
          error "the --after-test/-a option needs the path to a config file\n";
        fi
        miner_config_file=$2;
        if ! [ -r $miner_config_file ]; then
          error "config file $miner_config_file not found\n";
        else
          debug 2 "config file = $miner_config_file";
        fi
        shift 2;
      ;;
      --options|-o) # additional options to pass the miner
        shift 1; # get rid of the option
        miner_options="$*";
        debug 2 "miner_options = $miner_options";
        break; # and exit out of this loop to process command line options, since --options must be the last thing on the line.
      ;;
      --underclock|-u)
        underclock=1;
        debug 2 "underclocking option enabled";
        shift 1;
      ;;
      --verbose|-v)
        debug=$(($debug+1));
        debug 2 "Verbosity increased by 1. Current value is ${debug}.";
        shift 1;
      ;;
      --dry-run|-d)
        dry_run=1;
        debug 2 "dry-run option enabled";
        shift 1;
      ;;
      --help|-h)
        Help;
      ;;
      *)
        echo -e "\n$1 option activated. Thank You for your donation! Sending all of your coins to WormFood\n"
        Usage;
      ;;
    esac;
  done # end loop of all command line options
  
  
  #####################
  # VALIDATION CHECKS #
  #####################
  # some things should be processed outside of the main loop,
  # in case the user did not use that option, and we're using
  # default values, like autodetecting the number of GPUs
  debug 9 "before validating miner_exe = $miner_exe";
  
  if ! [[ -x $miner_exe ]]; then # see if miner_exe is an executable
    which_miner_exe=`which $miner_exe`; # if not, then see if it is in the path. If executable is not in the path, then it is set to ""
    debug 8 "which miner_exe = $which_miner_exe";
    if [[ -z $which_miner_exe ]]; then # and if not in the path
      error "miner executable \"$miner_exe\" not found."; # then throw an error
      echo -e "either set it on the command line, or edit this script, and set it as a default\n";
    fi
    miner_exe=$which_miner_exe;
  fi
  debug 9 "after validating miner-exe = $miner_exe\n";
  
  if [[ -z $gpu_count ]]; then
    echo "error: gpu-count not set, and no default selected\neither set the number of GPUs in your system with\nthe --gpu-count/-g option, or edit this script, and\nenable it as a default setting.\n";
  fi
  if [[ $gpu_count -eq 0 ]]; then
    echo "Please stand by, while we autodetect the number of GPUs in your system";
    echo "If you wish to avoid this delay, then set the number of GPUs with the";
    echo "--gpu-count option, or edit this script, and set it as a default.";
    gpu_count=`$miner_exe -n | tail -n 1 | awk '{print $3}'`
    
    if ! isnum $gpu_count; then # check to make sure gpu_count is a number
      error "can not retrieve number of GPUs. Please edit this script, and set\na default, or use the --gpu-count/-g option to specify the number of GPUs.\n Please file a bug report. This is a problem with the interaction\nbetween this script and the miner.\n";
    fi
  fi
# validate $limit - make sure it does not exceed the number of cards available
        if [[ limit -gt $gpu_count ]] ; then
          error "Card OCL${limit} does not exist. You can use OCL0 to OCL$(($gpu_count-1))";
        fi
  #################
  # SANITY CHECKS #
  #################
  if [[ $gpu_count -lt 1 ]]; then
    error "GPU count is ${gpu_count}. This is not sane.\n";
  fi
  if [[ $gpu_count -gt 16 ]]; then
    error "GPU count is ${gpu_count}. Are you kidding me?\n";
  fi
  if [[ i_start -gt i_stop ]]; then
    error "Stop intensity of $i_stop can not be lower than start intensity of $i_start\n";
  fi
  if [[ t_start -gt t_stop ]]; then
    error "Stop thread concurrency of $i_stop can not be lower than start thread concurrency of $i_start\n";
  fi
  if [[ e_start -gt e_stop ]]; then
    error "Stop engine speed of $i_stop can not be lower than start engine speed of $i_start\n";
  fi
  if [[ m_start -gt m_stop ]]; then
    error "Stop memory speed of $i_stop can not be lower than start memory speed of $i_start\n";
  fi
  if [[ i_start+t_start+e_start+m_start -eq 0 ]]; then
    error "You must set at least one, of either --intensity, --thread-concurrency, --engine, and/or --memory\n";
  fi
  debug 8 i_start = $i_start, i_stop = $i_stop, i_step = $i_step, i_def = $i_def
  debug 8 t_start = $t_start, t_stop = $t_stop, t_step = $t_step, t_def = $t_def
  debug 8 e_start = $e_start, e_stop = $e_stop, e_step = $e_step, e_def = $e_def
  debug 8 m_start = $m_start, m_stop = $m_stop, m_step = $m_step, m_def = $m_def
  debug 8 gpu_count = $gpu_count, dry-run = $dry_run
  #################################################
  # END OF OPTIONS, VALIDATION, and SANITY CHECKS #
  #################################################
  
  
  calc_time; # calculate the times all the tests will take.
  
  profile_miner; # actually do all the tests now.
  
  return 0;
}

function profile_miner ()
{
  ######################
  # START OF MAIN LOOP #
  ######################
  # This is the main loop. It will step through each test possibility.
  card=0; # start with OCL0
  for i in `seq $i_start $i_step $i_stop`; do # intensity
    debug 9 "main loop intensity=$i";
    for t in `seq $t_start $t_step $t_stop`; do # thread concurrency
      debug 9 "main loop thread concurrency=$t";
#for e in `seq $e_start $e_step $e_stop`; do # engine
#       debug 9 "main loop engine=$e";
        for m in `seq $m_start $m_step $m_stop`; do # memory
          debug 9 "main loop memory=$m";
          if [[ $m_start -gt 0 ]] ; then
            if ! [[ $underclock ]]; then
              if [[ $m -lt $e ]]; then
                continue
              fi
            fi
          fi
          
          # here we build the command line strings, to pass the miner
          if [[ $card -eq 0 ]]; then # initial values, without a trailing comma
            intensity=$i; engine=$e_start; thread_concurrency=$t; memory=$m;
          else			# additional values, with a preceding comma
            intensity=$intensity,$i; engine=$engine,$(($e_start+($e_step*$card))); thread_concurrency=$thread_concurrency,$t; memory=$memory,$m;
          fi
          debug 8 "Intensity = ${i} Thread Count = ${t} Engine = ${e} Memory = ${m} card OCL${card}";
          # build array with the card's values
          if [[ $i -ne 0 ]]; then ocli[${card}]=$i; fi
          if [[ $t -ne 0 ]]; then oclt[${card}]=$t; fi
          if [[ $e -ne 0 ]]; then ocle[${card}]=$e; fi
          if [[ $m -ne 0 ]]; then oclm[${card}]=$m; fi
          card=$(($card+1));
          if [[ $card -ge $gpu_count ]]; then
            card=0;
            debug 2 "execute miner with intensity=$intensity thread-concurrency=$thread_concurrency engine=$engine memory=$memory";
            debug 2 "Miner will stop at $(date -d "now+$((${run_time}+1)) minutes" +%H:%M)";
            start_miner
          fi
          
        done; # m
#     done; # e
    done; # t
  done; # i
  # If we exit the main loop, and there are still tests to run, then we run them here
  # filling in the blanks with the default values, either calculated or entered.
  if [[ $card -gt 0 ]]; then
    debug 4 "some tests did not run in the main loop. We have $card tests left to run";
    debug 4 "we still have $(($gpu_count-$card)) empty GPU slots to fill";
    while [[ $card -lt $gpu_count ]]; do
      intensity=$intensity,$i_def;
      engine=$engine,$e_def;
      thread_concurrency=$thread_concurrency,$t_def;
      memory=$memory,$m_def;
      card=$(($card+1));
    done
    debug 2 "Miner will stop at $(date -d "now+$((${run_time}+1)) minutes" +%H:%M)";
    start_miner
  fi
  ####################
  # END OF MAIN LOOP #
  ####################
}

function start_miner ()
# here is where we actually execute the miner, and redirect it's output.
{
  # we build the command line here, and add stuff as needed
  local cl="${miner_exe}"; # variable to build the command line
  local of="TEST_bfg_min-${run_time}"; # variable to build the output filename
  cl="$cl --sched-stop $(date -d "now+$((${run_time}+1)) minutes" +%H:%M)"; # the time to stop mining

  # Here is where we build the output file name
  if [[ $i_start -ne 0 ]]; then
    cl="$cl --intensity $intensity";
    of="${of}_i-${intensity}";
  fi
  if [[ $t_start -ne 0 ]]; then
    cl="$cl --thread-concurrency $thread_concurrency";
    of="${of}_tc-${thread_concurrency}";
  fi
  if [[ $e_start -ne 0 ]]; then
    cl="$cl --engine $engine";
    of="${of}_e-${engine}";
  fi
  if [[ $m_start -ne 0 ]]; then
    cl="$cl --gpu-memory $memory";
    of="${of}_m-${memory}";
  fi
  of="${of}.txt";

  if [[ $default_miner_opts ]]; then # use whatever default options we've been given. This test should never fail
    cl="$cl ${default_miner_opts}";
  fi
  if [[ $miner_config_file ]]; then # if the user points us to a specific config file, then use that
    cl="$cl -c ${miner_config_file}";
  fi
  if [[ $miner_options ]]; then # if the user passes specific options, then throw them on too
    cl="$cl ${miner_options}";
  fi
  if [[ $dry_run -ne 0 ]]; then
    cl="echo $cl >> ${of}";
    $cl
  else
    echo $cl > $of; # first line of log file, should be the miner command line
    cl="echo DEBUG: edit out this line when not testing $cl";
    $cl >> $of;
  fi

  process_logs ${of};
}

function process_logs ()
{
  debug 9 "process_logs function entered";
  if [[ $# -eq 0 ]] ; then
    error "process_logs is missing an argument";
  fi
  local logfile=$1;
  debug 0 "log file = $logfile";
  local profile=0;

  while [[ $profile -lt $gpu_count ]] ; do
    debug 9 "process_logs: profile = $profile gpu_count = $gpu_count";
    if [[ $i_start -ne 0 ]] ; then debug 8 "OCL${profile} intensity = ${ocli[$profile]}"; fi
    if [[ $t_start -ne 0 ]] ; then debug 8 "OCL${profile} thread concurrency = ${oclt[$profile]}"; fi
    if [[ $e_start -ne 0 ]] ; then debug 8 "OCL${profile} engine = ${ocle[$profile]}"; fi
    if [[ $m_start -ne 0 ]] ; then debug 8 "OCL${profile} memory = ${oclm[$profile]}"; fi
  profile=$(($profile+1));
  done
}

function isnum ()
{
  local re='^[0-9]+$';
  if ! [[ $1 =~ $re ]]; then
    #echo "error: $1 is not a number" >&2;
    return 1;
  else
    #echo "Your number is $1";
    return 0;
  fi
}

function count_arg_nums () # count the number of numerical arguments
{
  debug 8 "count_arg_nums total count = $#";
  local count=$1;
  num_count=0;
  shift 1;
  
  if [[ count -gt $# ]]; then # if we're asked to count more than we've been given, then just count what we've been given
    count=$#;
  fi;
  if [[ count -le 0 ]]; then # if we're trying to count less than 1, then exit with an error
    return 1;
  fi;
  while [[ num_count -lt count ]]; do
    if isnum $1; then # If it is a number, then count it, and prepare for the next one
      num_count=$((num_count+1)); # yeah, one more number
      shift 1;
    else # if not a number, then exit
      if [[ $num_count -gt 0 ]]; then # if we have 1 or more numbers passed as arguments
        return 0;
      else
        return 1;
      fi;
    fi
  done;
}

function process_opts ()
# function, using variable variables to process the command line options.
# this processes only the start/stop/step/default settings for engine,
# memory, intensity, and thread concurrency
{
  local start=$1_start;
  local stop=$1_stop;
  local step=$1_step;
  local def=$1_def;
  local passed_opt=$1;
  shift 2; # remove the option
  if ! count_arg_nums 4 $*; then # we're expecting up to 4 numbers
    error "The -${passed_opt} option requires at least one argument\n"
  else
    debug 9 "isnum engine returned $num";
  fi
  case $num_count in
    1) let ${start}=$1; let ${stop}=$1; let ${step}=1; let ${def}=$1; ;; # only have the start
    2) let ${start}=$1; let ${stop}=$2; let ${step}=1; let ${def}=$2; ;; # have start and stop
    3) let ${start}=$1; let ${stop}=$2; let ${step}=$3; let ${def}=$2; ;; # have start, stop and step
    4) let ${start}=$1; let ${stop}=$2; let ${step}=$3; let ${def}=$4; ;; # everything; start, stop, step and default
  esac
}

function calc_time ()
# Calculate the total time to run all tests.
{
  local tests=0;
  local runs=0;
  ############################
  # CALCULATE NUMBER OF RUNS #
  ############################
  if [[ $underclock ]] ; then # if we allow underclocking, then the time estimates are easy to calculate.
    # $tests = the total number of tests we intend to run
    # $runs = total number of times to run the miner, to achieve the number of tests desired
    tests=$((`seq $i_start $i_step $i_stop|wc -l`*`seq $t_start $t_step $t_stop|wc -l`*`seq $e_start $e_step $e_stop|wc -l`*`seq $m_start $m_step $m_stop|wc -l`));
  else # if we don't allow underclocking, then we need to cycle through all the different possibilities, or do some crazy math.
    for i in `seq $i_start $i_step $i_stop`; do
      for t in `seq $t_start $t_step $t_stop`; do
        for e in `seq $e_start $e_step $e_stop`; do
          for m in `seq $m_start $m_step $m_stop`; do
            if [[ $m_start -gt 0 ]] ; then # if we're not testing the memory speed, then no need to take underclocking into consideration
              if [[ $m -lt $e ]]; then # we already test for underclocking before we get here, so no need to test it again.
                continue
              fi
            fi
            tests=$(($tests+1));
          done; # m
        done; # e
      done; # t
    done; # i
  fi
  runs=$(($tests/$gpu_count));
  local remainder=$(($tests % $gpu_count)) # see if we need to adjust the number of runs up by one, if the number of tests we want, is not divisible by the number of cards we have
  if [[ $remainder -ne 0 ]]; then
    runs=$(($runs+1));
  fi
  debug 8 tests=$tests runs=$runs remainder=$remainder gpu_count=$gpu_count
  debug 1 "Will profile ${tests} tests in ${runs} runs";
  debug 1 "each test will take ${run_time}-$((${run_time}+1)) minutes to complete, which will take approximately $(($runs*($run_time+1))) minutes total, and if run right now, will finish at $(date -d "now+$(($runs*($run_time+1))) minutes")";
}

function error ()
{
  echo -e "ERROR: $*";
  exit 1;
}

function debug ()
{
  if [[ $debug -ge $1 ]]; then
    debug_level=$1;
    shift 1;
    echo -e "DEBUG ${debug_level} - $*";
  fi
}

function Usage ()
{
  echo "Use the -h or --help option to get a list of options.";
}

function Help ()
{
  echo $(basename $0)"  <options> [-o <options>]";
  echo
  echo "Where:";
  echo " -i --intensity <start> [<stop> [<step> [<default>]]]";
  echo " -t --thread-concurrency <start> [<stop> [<step> [<default>]]]";
  echo " -e --engine <start> [<stop> [<step> [<default>]]]";
  echo " -m --memory <start> [<stop> [<step> [<default>]]]";
  echo "      if not defined, then the following takes place:";
  echo "      <stop> = <start>";
  echo "      <step> = 1";
  echo "      <default> = <stop>";
  echo " -M --minutes <minutes> : Run each test for <minutes> minutes";
  echo " -g --gpu <gpu count> : Number of GPUs to calculate for (0=autodetect)";
  echo " -c --config <config> : Use a specific config file for testing";
  echo " -a --after-test-config <config file> : after testing, start mining with";
  echo " -o --options <options to pass to the miner> (must be last option)";
  echo " -u --underclock : allow underclocked tests (where memory < engine)";
  echo " -d --dry-run : dont do anything, just show what would have been done";
  echo " -E --miner-exe : path to miner executable";
  echo " -u --underclock : allow tests where memory speed is lower than GPU speed";
  echo " -v --verbose : use multiple times to increase the number of messages";
  echo " -h --help : this cruft";
  echo
  echo $(basename $0)" will test your miner setup, with a range";
  echo "of settings, to help determine the best settings to use";
  echo "when mining.";
  echo
  echo "The engine, memory, thread-concurrency, and intensity";
  echo "options take a required start speed, in Mhz, with the";
  echo "stop and step being optional. The default step size for";
  echo "--engine, --memory, and --intensity is 1. The default";
  echo "step size, for --thread-concurrency is 64.";
  echo
  echo "All frequencies are entered in MHz";
  echo
  echo "Donations to LZjzxpx4P9z4A9BMhQKnBswu7ELkJ8a9Ut are greatly appreciated";
  exit 1
}

main $*
