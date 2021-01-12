function _ct_help
    echo "ct <args> command"
    # echo "see ct -h -h for more help"
end
# 
# function _ct_more_help
    # echo "First, type `ct` in your terminal, followed by any arguments, then enter the name of the command you want to execute and press `Enter` or `Return`. See --help for more details"
# end

## rough order of TODOs:
# 1. Add extremely basic dep management
#   - add default resolvers and download libs
#   - download dep's deps?
# 2. Set up testing
#   - download junit
#   - run tests with test command
# 3. Create jars with deps
#   - dump the 'mono-folder' joke if becomes too much of a pain
# 4. Add support for modules
#   - this will need a lot of research
# 5. Write a slightly more extensive application using recent java features
# 6. Make something useful and use tool to push up to resolver

# Less important bits or just that might come up
# - fix asdf installation
# - generalize reading from project.cool
# - save data in a .cool folder instead of all env vars and write functionings to read and set those
function ct
    set_color -b black
    set_color brmagenta
    echo "Welcome to cooltool! Your personal robust bespoke mono-directory Java build tool."
    argparse 'h/help' -- $argv

    if test -n "$_flag_h" #-a $_flag_h -gt 0
        _ct_help
    # else if $more_help
        # _ct_more_help
    else 
        _ct_read_cool_file
        if test $status -eq 1
            echo "Problem finding cooltool file (.cool). Is this a cooltools project? Maybe you meant `ct init`?"
            return
        end
        for cmd in $argv #remaining should be just commands
            #echo cmd is $cmd
            switch $cmd
                case "help"
                    _ct_help
                case init
                    _ct_init
                case reload
                    _ct_reload
                case clean
                    _ct_clean
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
                case debug_clean
                    _ct_clean
                    rm -fr .asdf
                case check_file_scope
                    echo "--------------------------------------"
                    echo "    main_java: $_ct_proj_main_java"
                    echo "main_compiled: $_ct_proj_main_compiled"
                    echo "main_resource: $_ct_proj_main_resource"
                    echo "    test_java: $_ct_proj_test_java"
                    echo "test_compiled: $_ct_proj_test_compiled"
                    echo "test_resource: $_ct_proj_test_resource"
                    echo "       ignore: $_ct_proj_ignore"
                    echo "--------------------------------------"
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
    _ct_init
    _ct_install_java
    set -xg _ct_proj_directory $PWD #make sure this doesn't change
end

function _ct_clean
    for file in $_ct_proj_main_compiled
        rm $file
        set -e _ct_proj_main_compiled
    end
    for file in $_ct_proj_test_compiled
        rm $file
        set -e _ct_proj_test_compiled
    end
    rm *.jar
end

function _ct_read_cool_file
    # read in .cool file
    # set important values as env variables
    if test (count $argv) -eq 0
        set file (ls | grep .cool)
        if test -z $file 
            echo "returning?"
            false #set status to 1
            return
        end
    else
        set file $argv[1]
    end
    set -e _ct_proj_name
    set -e _ct_mainclass
    set -e _ct_java_ver
    set -xg _ct_use_local_asdf "false"
    while read -la -d "\n" line
        switch $line
            case "project=*"
                set -xg _ct_proj_name (_snip $line)
            case "mainclass=*"
                set -xg _ct_mainclass (_snip $line)
            case "java_version=*"
                set -xg _ct_java_ver  (_snip $line)
            case "use_local_asdf=*"
                if test (_snip $line) = "true"
                    set -xg _ct_use_local_asdf "true" 
                end
            case "*"
        end
    end < $file
end

#if no _ct_java_ver assigned, use openjdk-15
#check if _ct_java_ver installed, skip install if true
#check if _ct_java_ver is a real asdf version, return false if true
#install version if needed
function _ct_install_java
    set -x _ct_default_java "openjdk-15" #only support exact strings that asdf expects

    if test -z $_ct_java_ver
        echo "No java version set, using $_ct_default_java instead"
        set _ct_java_ver $_ct_default_java
    end


    if contains $_ct_java_ver ($_ct_asdf list java | string split ' ')
        echo "Correct java version already installed"
    else
        if contains $_ct_java_ver ($_ct_asdf list all java | string split ' ')
            echo installing $_ct_java_ver
            $_ct_asdf install java $_ct_java_ver
        else
            echo "$_ct_java_ver not recognized"
            false
            return #see if this actually returns
        end
    end
end 

function _ct_assign_java 
    # if test (_ct_asdf_check_current_version $_ct_java_ver) = "true" #does that actually work?
        # echo "Correct java version already assigned"
    # else
    echo assigning $_ct_java_ver to local
    $_ct_asdf local java $_ct_java_ver  
end

function _ct_asdf_check_current_version
    echo "false"
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

#TODO get asdf to only install for project, not for shell
function _ct_init

    if test $_ct_use_local_asdf = "true"
        set -xg _ct_asdf "asdf"
    else
        echo "downloading asdf is not supported yet!"
        #download asdf for java version management
        #check if init is finished already or needs repairing?
        # if test ! \( -e .asdf \) -o ! \( -d .asdf \) #if not .asdf exsits and is a dir
            # curl -o asdf.zip https://codeload.github.com/asdf-vm/asdf/zip/v0.8.0
            # unzip asdf.zip
            # mkdir .asdf
            # cp -r asdf-0.8.0/lib .asdf/lib
            # cp -r asdf-0.8.0/bin .asdf/bin
            # rm -r asdf-0.8.0
            # rm asdf.zip
            # set -l ASDF_DATA_DIR .asdf
            # .asdf/bin/asdf plugin-add java https://github.com/halcyon/asdf-java.git
        # else
            # echo "??????????????"
        # end
        #.asdf/asdf.sh plugin add https://github.com/halcyon/asdf-java.git
    end
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
    #assumes we're in the correct dir
    java $_ct_mainclass
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

#only maven for now
function _ct_download_dep
    set -l _repo https://repo.maven.apache.org/maven2

    set -l _dep (string split ":" $argv[1])

    if test ! (count $_dep) -eq 3
        echo wtf
    end

    #"package":"lib":"version"

    set -l _package (string replace "." "/" $_dep[1])  # replace dots with slashes 
    set -l _name $_dep[2]
    set -l _version $_dep[3]
    set -l _jar "$_name-$_version.jar"

#download not as big as expected?
    echo "$_repo/$_package/$_name/$_version/$_jar"
    curl -o $_jar "$_repo/$_package/$_name/$_version/$_jar"
end

#.cool file
#format:
# like project.cool but used to maintain state instead of env vars
# how do you prevent overwrites from multiple processes?
#
# 
# random but:
# fish .set notes:
# - default if no scope is for the *current function*
# -     this is different than -l
function _ct_read

end

function _ct_write

end
