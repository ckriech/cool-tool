function _ct_help
    echo "ct <args> command"
    # echo "see ct -h -h for more help"
end
# 
# function _ct_more_help
    # echo "First, type `ct` in your terminal, followed by any arguments, then enter the name of the command you want to execute and press `Enter` or `Return`. See --help for more details"
# end

function ct
    set_color -b black
    set_color brmagenta
    echo "Welcome to cooltool! Your personal robust bespoke Java build tool."
    argparse 'h/help' -- $argv

    if test -n "$_flag_h" #-a $_flag_h -gt 0
        _ct_help
    # else if $more_help
        # _ct_more_help
    else 
        _ct_read_cool_file
        for cmd in $argv #remaining should be just commands
            echo cmd is $cmd
            switch $cmd
                case init
                    _ct_init
                case reload
                    _ct_reload
                case compile compile_main    
                    _ct_compile "main"
                case compile_test
                    _ct_compile "test"
                case run run_main
                    _ct_run
                case assemble
                    _ct_assemble
                case "test" run_test
                    _ct_test
                case check_file_scope
                    echo _ct_proj_ignore
                    echo main_java:     $_ct_proj_main_java
                    echo main_compiled: $_ct_proj_main_compiled
                    echo main_resource: $_ct_proj_main_resource
                    echo test_java:     $_ct_proj_test_java
                    echo test_compiled: $_ct_proj_test_compiled
                    echo test_resource: $_ct_proj_test_resource
                    echo ignore:        $_ct_proj_ignore
                case "*"
                    echo "No idea what $cmd is"
            end
        end
    end

    set_color normal
end

function _ct_reload
    _ct_read_cool_file
    _ct_tag_files
    set -xg _pt_proj_directory $PWD #make sure this doesn't change
end

function _ct_read_cool_file
    # read in .cool file
    # set important values as env variables
    if test (count $argv) -eq 0
        set file (ls | grep .cool)
    else  
        set file $argv[1]
    end
    while read -la -d "\n" line
        switch $line
            case "project=*"
                set -xg _pt_proj_name (_snip $line)
            case "mainclass=*"
                set -xg _pt_mainclass (_snip $line)
            case "*"
        end
    end < $file
end

function _ct_tag_files #set scope for all files in dir
    #reset scopes
    set -e _ct_proj_ignore
    set -e _ct_proj_main_java
    set -e _ct_proj_main_compiled
    set -e _ct_proj_main_resource
    set -e _ct_proj_test_java
    set -e _ct_proj_test_compiled
    set -e _ct_proj_test_resource
    for file in (ls)
        set -l scope (_ct_get_scope_file $file) 
        # echo file $file is $scope
        set -xga _ct_proj_$scope $file           
    end
end

function _snip
    echo $argv[1] | sed 's/.*=//g' 
end

function _ct_init

end

function _ct_compile
    switch "$argv[1]"
        case "main"
            set -x files $_ct_proj_main_java
        case "test"
            set -x files $_ct_proj_test_java
        case "*"
            #echo "????"
    end
    javac $files
    _ct_tag_files
end
 
function _ct_run 
    #download java?
    #assumes we're in the correct dir
    java $_pt_mainclass
end

function _ct_assemble #make jar
    jar cf "$_ct_proj_name.jar" $_ct_proj_main_compiled
end

function _ct_test

end

function _ct_get_scope_file
    if test -d $argv[1]
        echo "ignore"
    else
        switch $argv[1]
            case "*.cool" "*.jar" ".git*" "*/" "*.fish"
                echo "ignore"
            case "*Test*.java"
                echo "test_java"
            case "*Test*.class"
                echo "test_compiled"
            case "*Test*"
                echo "test_resource"
            case "*.java"
                echo "main_java"
            case "*.class"
                echo "main_compiled"
            case "*"
                echo "main_resource"
        end
    end
end
