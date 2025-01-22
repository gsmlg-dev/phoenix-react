#!/bin/bash


replace() {

FROM=${1}
TO=${2}

PWD=$(pwd)
DIR=${3:-$PWD}

if [[ -z $FROM ]] || [[ -z $TO ]]
then
    echo "replace [from] [to] [*path]"
    exit 1
fi

#echo replace $FROM to  $TO in  $DIR

#echo "ag -l -Q $FROM $DIR"

for FILE in $(ag -l -Q "$FROM" "$DIR");
do
    echo $FILE;
    if [[ "$(uname -s)" == 'Darwin' ]]
    then
    	sed -i '' "s%$FROM%$TO%g" $FILE;
    else 
    	sed -i "s%$FROM%$TO%g" $FILE;
    fi
done

}


replace '<app_otp_name>' 'opt_name'

replace '<app_otp_name>' 'opt_name' '.releaserc.yaml'

replace 'TemplateModuleName' 'ModuleName'

mv 'lib/template_module_name.ex' 'lib/module_name.ex'

mv 'test/template_module_name_test.exs' 'test/module_name.exs'

