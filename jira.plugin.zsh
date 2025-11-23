# Enable jira plugin only if jira command is available
if [[ -z $commands[jira] ]]; then
	return
fi

# If the completion file doesn't exist yet, we need to autoload it and
# bind it to `jira`. Otherwise, compinit will have already done that.x
if [[ ! -f "$ZSH_CACHE_DIR/completions/_jira" ]]; then
	typeset -g -A _comps
	autoload -Uz _jira
	_comps[jira]=_jira

	jira completion zsh >|"$ZSH_CACHE_DIR/completions/_jira"
fi

# ============= DEFAULT CONFIGURATION ============= #

JIRA_ISSUE_COMPONENT=${JIRA_ISSUE_COMPONENT}
JIRA_ISSUE_DONE_STATUS=${JIRA_ISSUE_DONE_STATUS-"Completed"}
JIRA_AUTO_STATUS=${JIRA_AUTO_STATUS-"In Progress"}
JIRA_AUTO_ASSIGN=${JIRA_AUTO_ASSIGN-"currentUser()"}
JIRA_ISSUE_FILTER=${JIRA_ISSUE_FILTER-"status = \"TO DO\" AND (assignee = currentUser() OR reporter = currentUser())"}
JIRA_DEFAULT_TASK_TYPE=${JIRA_DEFAULT_TASK_TYPE-"Task"}

# ================ INTERNAL HELPERS =============== #

_jira_get_issue_field() {
	local field_name=$1
	local issue_id=$2

	jira issue list -q "ID = ${issue_id}" --plain --no-headers --columns "${field_name}" | grep -o "[^$(echo -e \\t)]\+$"
}

# resolve a the requested epic issue by the user's epic map
_jira_get_epic_id() {
	local git_remote=$(__git_prompt_git config --get remote.origin.url)
	local returnValue="${JIRA_EPIC_MAP+${JIRA_EPIC_MAP[$git_remote]}}"

	if [ -n "$returnValue" ]; then
		echo "$returnValue"
	fi
}

# get the current type of a jira issue
_jira_get_epic_type() {
	_jira_get_issue_field "TYPE" $1
}

# resolve what type of issue to create fo a specific epic type
# AKA if epic is of type "Lifter" create a "Sub-task", if epic is of type "Epic" create a "Task"
_jira_get_task_type() {
	local LOCAL_JIRA_DEFAULT_TASK_TYPE=${JIRA_DEFAULT_TASK_TYPE}
	local CURRENT_JIRA_EPIC_ID=$1

	if [ -z $CURRENT_JIRA_EPIC_ID ]; then
		echo $LOCAL_JIRA_DEFAULT_TASK_TYPE
		return
	fi

	local epic_type=$(_jira_get_epic_type $CURRENT_JIRA_EPIC_ID)

	typeset -A default_epic_type=(
		"Lifter" "Sub-task"
		"Epic" "Task"
	)

	local returnValue

	if [ -z "$JIRA_TYPE_MAP" ]; then
		returnValue="${default_epic_type[$epic_type]}"
	else
		returnValue="${JIRA_TYPE_MAP[$epic_type]}"
	fi

	if [ -n "$returnValue" ]; then
		echo "$returnValue"
	else
		echo $LOCAL_JIRA_DEFAULT_TASK_TYPE
	fi
}

# ================== USER FACING ================== #

# Jira Issue List
alias jil='jira issue list -q "${JIRA_ISSUE_FILTER}"'

# Jira Issue Create
function jic {
	local CURRENT_JIRA_EPIC_ID=$(_jira_get_epic_id)
	local CURRENT_TASK_TYPE=$(_jira_get_task_type $CURRENT_JIRA_EPIC_ID)

	jira issue create -t${CURRENT_TASK_TYPE} "${CURRENT_JIRA_EPIC_ID:+"-P$CURRENT_JIRA_EPIC_ID"}"
}

# "smart" Jira Issue Create
function jjic {
	if [ -z $1 ]; then
		echo "Issue summary not found!"
		echo ""
		echo 'usage: jjic <issue summary>'
		return 1
	fi

	local CURRENT_JIRA_EPIC_ID=$(_jira_get_epic_id)
	local CURRENT_TASK_TYPE=$(_jira_get_task_type $CURRENT_JIRA_EPIC_ID)

	local JIRA_ISSUE_CREATE_PARAMS=()

	if [ -n "$CURRENT_TASK_TYPE" ]; then JIRA_ISSUE_CREATE_PARAMS+=("-t${CURRENT_TASK_TYPE}"); fi
	if [ -n "$CURRENT_JIRA_EPIC_ID" ]; then JIRA_ISSUE_CREATE_PARAMS+=("-P${CURRENT_JIRA_EPIC_ID}"); fi
	if [ -n "$JIRA_ISSUE_COMPONENT" ]; then JIRA_ISSUE_CREATE_PARAMS+=("-C${JIRA_ISSUE_COMPONENT}"); fi
	if [[ "${JIRA_AUTO_ASSIGN}" != "EMPTY" ]]; then JIRA_ISSUE_CREATE_PARAMS+=("-a${JIRA_AUTO_ASSIGN}"); fi

	local JIRA_ISSUE_ID="$(jira issue create ${JIRA_ISSUE_CREATE_PARAMS[@]} --no-input --summary "$(echo $*)" | grep -oE '[A-Z]{2,}-\d+')"
	local JIRA_ISSUE_SUMMARY=$(echo "$(echo $*)" | tr -dc '[:alnum:] ' | tr '[:upper:]' '[:lower:]' | tr -s ' ' | sed 's/ /-/g')

	git checkout -b "$JIRA_ISSUE_ID-$JIRA_ISSUE_SUMMARY" $(git_main_branch)

	print -s "git commit -m \"$(echo $*)\""

	if [[ "${JIRA_AUTO_STATUS}" != "EMPTY" ]]; then
		jira issue move "$JIRA_ISSUE_ID" "${JIRA_AUTO_STATUS}"
	fi
}

# Jira Issue Move
function jim {
	jira issue move "$1" "${JIRA_ISSUE_DONE_STATUS}"
}

# "Smart" Jira Issue Move
function jjim {
	local JIRA_ISSUE_REGEX="^[A-Z]{2,}-[0-9]+"
	local jiraIssue=$(git_current_branch | grep -oE "${JIRA_ISSUE_REGEX}" | head -1)

	if [ -z "${jiraIssue}" ]; then
		echo "no jira issues found in '$(git_current_branch)'"
		return 1
	fi

	jim "${jiraIssue}"
}

# "smart" Jira Issue detection
function jji {
	local JiraIssueId=$1

	if [ -z $JiraIssueId ]; then
		echo "Issue number missing!"
		echo ""
		echo 'usage: jji <issue id>'
		return 1
	fi

	local CURRENT_JIRA_EPIC_ID=$(_jira_get_epic_id)
	local CURRENT_TASK_TYPE=$(_jira_get_task_type $CURRENT_JIRA_EPIC_ID)

	local JIRA_ISSUE_CREATE_PARAMS=()

	if [ -n "$CURRENT_TASK_TYPE" ]; then JIRA_ISSUE_CREATE_PARAMS+=("-t${CURRENT_TASK_TYPE}"); fi
	if [ -n "$CURRENT_JIRA_EPIC_ID" ]; then JIRA_ISSUE_CREATE_PARAMS+=("-P${CURRENT_JIRA_EPIC_ID}"); fi
	if [ -n "$JIRA_ISSUE_COMPONENT" ]; then JIRA_ISSUE_CREATE_PARAMS+=("-C${JIRA_ISSUE_COMPONENT}"); fi
	if [[ "${JIRA_AUTO_ASSIGN}" != "EMPTY" ]]; then JIRA_ISSUE_CREATE_PARAMS+=("-a${JIRA_AUTO_ASSIGN}"); fi

	local JIRA_ISSUE_SUMMARY_TEXT=$(_jira_get_issue_field "SUMMARY" $JiraIssueId)

	local JIRA_ISSUE_SUMMARY=$(echo "$JIRA_ISSUE_SUMMARY_TEXT" | tr -dc '[:alnum:] ' | tr '[:upper:]' '[:lower:]' | tr -s ' ' | sed 's/ /-/g')

	git checkout -b "$1-$JIRA_ISSUE_SUMMARY" $(git_main_branch)

	print -s "git commit -m \"$JIRA_ISSUE_SUMMARY_TEXT\""
}
