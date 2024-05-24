



userGen(){
CORE_USER="core"
CORE_HOME="/home/$CORE_USER"


MENTEE_DETAILS="$1"
MENTOR_DETAILS="$2"

if [ ! -f "$MENTEE_DETAILS" ] || [ ! -f "$MENTOR_DETAILS" ]; then
        echo "Mentee or mentor details file not found."
        return 1
    fi

useradd -m $CORE_USER


MENTORS_DIR="$CORE_HOME/mentors"
MENTEES_DIR="$CORE_HOME/mentees"
mkdir -p "$MENTORS_DIR" "$MENTEES_DIR"



chmod 777 $CORE_HOME
chown $CORE_USER:$CORE_USER $CORE_HOME


tail -n +2 "$MENTEE_DETAILS" | while read -r line; do
    mentee_name=$(echo "$line" | awk '{print $1}')
    mentee_user="${mentee_name,,}"  
    useradd -m -d "$MENTEES_DIR/$mentee_user" "$mentee_user"
    mkdir -p "$MENTEES_DIR/$mentee_user"
    touch "$MENTEES_DIR/$mentee_user/domain_pref.txt"
    touch "$MENTEES_DIR/$mentee_user/task_completed.txt"
    touch "$MENTEES_DIR/$mentee_user/task_submitted.txt"
    chmod 700 "$MENTEES_DIR/$mentee_user"
    chown -R $mentee_user:$mentee_user $MENTEES_DIR/$mentee_user
    setfacl -m u:$CORE_USER:rwx $MENTEES_DIR/$mentee_user
done



tail -n +2 "$MENTOR_DETAILS" | while read -r line; do
    mentor_name=$(echo "$line" | awk '{print $1}')
    domain=$(echo "$line" | awk '{print $2}')
    mentor_user="${mentor_name,,}"
    domain_dir="$MENTORS_DIR/$domain"


    mkdir -p "$domain_dir"

    useradd -m -d "$domain_dir/$mentor_user" "$mentor_user"
    mkdir -p "$domain_dir/$mentor_user"
    touch "$domain_dir/$mentor_user/allocatedMentees.txt"
    mkdir -p "$domain_dir/$mentor_user/submittedTasks/task1"
    mkdir -p "$domain_dir/$mentor_user/submittedTasks/task2"
    mkdir -p "$domain_dir/$mentor_user/submittedTasks/task3"
    chmod 700 "$domain_dir/$mentor_user"
    chown -R $mentor_user:$mentor_user $domain_dir/$mentor_user
    setfacl -m u:$CORE_USER:rwx $domain_dir/$mentor_user
done

touch "$CORE_HOME/mentees_domain.txt"
chmod 722 "$CORE_HOME/mentees_domain.txt"


echo "Setup complete."

}

 domainPref(){
mentee_home="$HOME"
core_home="/home/core"
mentee_name=$(basename "$mentee_home")
 domain_pref_file="$mentee_home/domain_pref.txt"
 core_domain_file="$core_home/mentees_domain.txt"
roll_no=""
 preferences=()

    echo "Enter your roll number:"
    read -r roll_no

    echo "Enter your domain preferences (up to 3,Note:type web or app or sysad), one by one:"
    for i in 1 2 3; do
        echo "Preference $i (leave blank if no more preferences):"
        read -r domain
        if [ -z "$domain" ]; then
            break
        fi
        preferences+=("$domain")
    done


    echo "Roll Number: $roll_no" > "$domain_pref_file"
    echo "Name : $mentee_name" >> "$domain_pref_file"
    echo "Preferences:" >> "$domain_pref_file"
    for pref in "${preferences[@]}"; do

        echo "$pref" >> "$domain_pref_file"
        
          mkdir -p "$mentee_home/$pref"
          mkdir -p "$mentee_home/$pref/task1"
          mkdir -p "$mentee_home/$pref/task2"
          mkdir -p "$mentee_home/$pref/task3"
     done

    
    echo -n "$roll_no : $mentee_name : " >> "$core_domain_file"
    IFS=','; echo "${preferences[*]}" >> "$core_domain_file"
    IFS=' '
   
   
    echo "Domain preferences updated successfully."
 }


 mentorAllocation(){
      local core_home="/home/core"
    local mentee_details="$core_home/mentees_domain.txt"
    local mentor_details="mentor.txt"
    declare -A mentor_capacity
    declare -A mentor_allocation
    declare -a mentor_web
    declare -a mentor_sysad
    declare -a mentor_app

 
    while read -r line; do
        mentor_name=$(echo "$line" | awk '{print $1}')
        domain=$(echo "$line" | awk '{print $2}')
        capacity=$(echo "$line" | awk '{print $3}')
       if [[ -z "$mentor_name" ]]; then
            continue
        fi
 mentor_user="${mentor_name,,}"
        mentor_home="/home/$mentor_user"

        mentor_capacity["$mentor_user"]=$capacity
        mentor_allocation["$mentor_user"]=""
        first_char="${domain:0:1}"
        if [[ "$first_char" == [Ww] ]]; then
            mentor_web+=("$mentor_user")
        elif [[ "$first_char" == [Aa] ]]; then
            mentor_app+=("$mentor_user")
        elif [[ "$first_char" == [Ss] ]]; then
            mentor_sysad+=("$mentor_user")
        fi
    done < <(tail -n +2 "$mentor_details")


    while read -r line; do
        mentee_name=$(echo "$line" | awk '{print $3}')
        roll_no=$(echo "$line" | awk '{print $1}')
        domains=$(echo "$line" | awk '{print $5}')
        IFS=',' read -r -a array <<< "$domains"
        for domain in "${array[@]}"; do
            first_char="${domain:0:1}"
            if [[ "$first_char" == [Ww] ]]; then
                mentor="${mentor_web[0]}"
                if [[ ${mentor_capacity[$mentor]} -gt 0 ]]; then
                    echo -n "$mentee_name $roll_no"$'\n' >> "$core_home/mentors/web/$mentor/allocatedMentees.txt"
                     setfacl -m u:$mentor:rwx /home/core/mentees/$mentee_name/domain/task1
                     setfacl -m u:$mentor:rwx /home/core/mentees/$mentee_name/domain/task2
                     setfacl -m u:$mentor:rwx /home/core/mentees/$mentee_name/domain/task3
                    ((mentor_capacity[$mentor]--))
                else
                    unset 'mentor_web[0]'
                    mentor="${mentor_web[0]}"
                    echo -n "$mentee_name $roll_no"$'\n' >> "$core_home/mentors/web/$mentor/allocatedMentees.txt"
                      setfacl -m u:$mentor:rwx /home/core/mentees/$mentee_name/domain/task1
                     setfacl -m u:$mentor:rwx /home/core/mentees/$mentee_name/domain/task2
                     setfacl -m u:$mentor:rwx /home/core/mentees/$mentee_name/domain/task3
                    ((mentor_capacity[$mentor]--))
                fi
            elif [[ "$first_char" == [Aa] ]]; then
                mentor="${mentor_app[0]}"
                if [[ ${mentor_capacity[$mentor]} -gt 0 ]]; then
                    echo -n "$mentee_name $roll_no"$'\n' >> "$core_home/mentors/app/$mentor/allocatedMentees.txt"
                      setfacl -m u:$mentor:rwx /home/core/mentees/$mentee_name/domain/task1
                     setfacl -m u:$mentor:rwx /home/core/mentees/$mentee_name/domain/task2
                     setfacl -m u:$mentor:rwx /home/core/mentees/$mentee_name/domain/task3
                    ((mentor_capacity[$mentor]--))
                else
                    unset 'mentor_app[0]'
                    mentor="${mentor_web[0]}"
                    echo -n "$mentee_name $roll_no"$'\n' >> "$core_home/mentors/web/$mentor/allocatedMentees.txt"
                     setfacl -m u:$mentor:rwx /home/core/mentees/$mentee_name/domain/task1
                     setfacl -m u:$mentor:rwx /home/core/mentees/$mentee_name/domain/task2
                     setfacl -m u:$mentor:rwx /home/core/mentees/$mentee_name/domain/task3
                    ((mentor_capacity[$mentor]--))
                fi
            elif [[ "$first_char" == [Ss] ]]; then
                mentor="${mentor_sysad[0]}"
                if [[ ${mentor_capacity[$mentor]} -gt 0 ]]; then
                    echo -n "$mentee_name $roll_no"$'\n' >> "$core_home/mentors/sysad/$mentor/allocatedMentees.txt"
                      setfacl -m u:$mentor:rwx /home/core/mentees/$mentee_name/domain/task1
                     setfacl -m u:$mentor:rwx /home/core/mentees/$mentee_name/domain/task2
                     setfacl -m u:$mentor:rwx /home/core/mentees/$mentee_name/domain/task3
                    ((mentor_capacity[$mentor]--))
                else
                    unset 'mentor_sysad[0]'
                    mentor="${mentor_web[0]}"
                     echo -n "$mentee_name $roll_no"$'\n' >> "$core_home/mentors/web/$mentor/allocatedMentees.txt"
                      setfacl -m u:$mentor:rwx /home/core/mentees/$mentee_name/domain/task1
                     setfacl -m u:$mentor:rwx /home/core/mentees/$mentee_name/domain/task2
                     setfacl -m u:$mentor:rwx /home/core/mentees/$mentee_name/domain/task3
                    ((mentor_capacity[$mentor]--))
                   
                fi
            fi
        done
    done < <(tail -n +2 "$mentee_details")

    echo "Mentor allocation completed successfully."

 }

 submitTask(){
    user_home=~

if [[ "$user_home" == *"/mentees/"* ]]; then
echo "Enter your task details. Press Ctrl+D when you're done:"
details=""
while IFS= read -r line; do
    details+="$line"$'\n'
done
echo "$details" >>  "$user_home/task_submitted.txt"
echo $'\n'"What domain?(web or app or sysad)"
read  domain
echo "which task(1 or 2 or 3)?"
read  task_no
echo "Enter the directory  path where your task is stored "
read path
mv "$path" "$user_home/$domain/task$task_no"
declare -A array
for subdirectory in "$user_home"/*/; do
    subdirectory_name=$(basename "$subdirectory")
    array["${subdirectory_name}"]="${subdirectory_name}:"$'\n'
    if [ -d "$subdirectory" ]; then
        for task_directory in "$subdirectory"/*/; do
            task_directory_name=$(basename "$task_directory")
            if [ -d "$task_directory" ]; then
                if [ -z "$(ls -A "$task_directory")" ]; then
                    array["${subdirectory_name}"]+="     ${task_directory_name}: n"$'\n'
                else
                    array["${subdirectory_name}"]+="     ${task_directory_name}: y"$'\n'
                fi
            fi
        done
    fi
done

echo " " > "$user_home/task_completed.txt"
for str in "${array[@]}"; do
      echo "$str" >> "$user_home/task_completed.txt"
done
else
      mentee_details="$user_home/allocatedMentees.txt"
mentor_domain=$(basename "$(dirname "$user_home")")
while IFS= read -r line; do
      echo "$line"
    mentee_name=$(echo "$line" | awk '{print $1}')

        mkdir  "$user_home/submittedTasks/task1/$mentee_name"
        mkdir   "$user_home/submittedTasks/task2/$mentee_name"
        mkdir   "$user_home/submittedTasks/task3/$mentee_name"
        ln -s "/home/core/mentees/$mentee_name/$mentor_domain/task1" "$user_home/submittedTasks/task1/$mentee_name"
        ln -s "/home/core/mentees/$mentee_name/$mentor_domain/task2" "$user_home/submittedTasks/task2/$mentee_name"
        ln -s "/home/core/mentees/$mentee_name/$mentor_domain/task3" "$user_home/submittedTasks/task3/$mentee_name"

done < "$mentee_details"

fi
 }

 displayStatus(){


    user_home=~

declare -i total_task_assigned
declare -i total_completed

while read -r line; do
    mentee_name=$(echo "$line" | awk '{print $3}')
    domains=$(echo "$line" | awk '{print $5}')
    IFS=',' read -r -a domain_array <<< "$domains"

    for domain in "${domain_array[@]}"; do
        total_task_assigned+=3

        for task_number in {1..3}; do
            task_directory="$user_home/mentees/$mentee_name/$domain/task$task_number"
            if [ -d "$task_directory" ]; then
                total_completed+=1
            fi
        done
    done

done < <(tail -n +2 "$user_home/mentees_domain.txt")

percentage=$((100 * total_completed / total_task_assigned))
echo "Percentage of tasks completed: $percentage"

LAST_RUN_FILE="$user_home/displayStatus_last_run.txt"
current_time=$(date +%s)
last_run_time=$(cat "$LAST_RUN_FILE" 2>/dev/null || echo 0)
echo "$current_time" > "$LAST_RUN_FILE"
diff=$((current_time - last_run_time))

if [ -z "$1" ]; then
    domains=("web" "sysad" "app")
else
    domains=("$1")
fi
while read -r line; do
    mentee_name=$(echo "$line" | awk '{print $3}')
    mentee_domains=$(echo "$line" | awk '{print $5}')
    IFS=',' read -r -a mentee_domain_array <<< "$mentee_domains"

    for domain in "${mentee_domain_array[@]}"; do
        if [[ " ${domains[@]} " =~ " $domain " ]]; then
            for task_number in {1..3}; do
                task_directory="$user_home/mentees/$mentee_name/$domain/task$task_number"
                if [ -d "$task_directory" ]; then
                    file_modification_time=$(stat -c %Y "$task_directory")
                    diff_file=$((current_time - file_modification_time))
                    if [ "$diff" -gt "$diff_file" ]; then
                        echo "Name: $mentee_name, domain: $domain, task$task_number completed"
                    fi
                fi
            done
        fi
    done

done < <(tail -n +2 "$user_home/mentees_domain.txt")


 }
