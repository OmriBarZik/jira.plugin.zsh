# jira.plugin.zsh

This plugin purpose is to make sure to DON'T need to use the web interface of Jira.

## Pre-Requirements

- [Oh My zsh](https://ohmyz.sh/#install)
- [Jira CLI](https://github.com/ankitpokhrel/jira-cli) configured [(How to install)](https://github.com/ankitpokhrel/jira-cli/wiki/Installation)

## Installation

1. Clone this repository into $ZSH_CUSTOM/plugins (by default ~/.oh-my-zsh/custom/plugins)

```bash
git clone https://github.com/omribarzik/jira.plugin.zsh.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/jira
```

2. Run this command to enable the plugin

```bash
omz plugin enable jira
```

3. Start a new terminal session, or run

```bash
omz reload
```

## Update

```bash
git -C ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/jira pull origin main
```

## Aliases

| Alias | command                                                                 | Description                                                                  |
| ----- | ----------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| jil   | jira issue list -q ${JIRA_ISSUE_FILTER}                                 | list all issue with filter                                                   |
| jim   | jira issue move \<jira issue\> ${JIRA_ISSUE_DONE_STATUS}                | move your jira issue to done status                                          |
| jic   | jira issue create -tTask                                                | create new jira issue                                                        |
| jjic  | jira issue create && git checkout -b \<jira issue\>                     | create new issue and new branch with the same summary from master            |
| jji   | jira issue view \<issue id\> && git checkout -b \<jira issue\>          | create a new branch with the same summary from an existing issue             |
| jjim  | jira issue move \<current branch jira issue\> ${JIRA_ISSUE_DONE_STATUS} | move your current jira issue to done status (get jira issue from git branch) |

## Configuration

Every company works and every team works differently, so to make this plugin more useful you can configure it with the following environment variables.

make sure to add them to your `~/.zshrc` file

### JIRA_ISSUE_FILTER

Controls what issue to list in `jil` make sure it written in [jira query language](https://support.atlassian.com/jira-service-management-cloud/docs/use-advanced-search-with-jira-query-language-jql) (JQL)

#### Default value

```bash
JIRA_ISSUE_FILTER='status = "TO DO" AND (assignee = currentUser() OR reporter = currentUser())'
```

### JIRA_ISSUE_DONE_STATUS

Controls to what status to move your jira issue ih `jim`

#### Default value

```bash
JIRA_ISSUE_DONE_STATUS='Completed'
```

### JIRA_AUTO_ASSIGN

To what user to auto assign when running `jjic`, to disable enter empty value (`""`)

#### Default value

```bash
JIRA_AUTO_ASSIGN='currentUser()'
```

### JIRA_AUTO_STATUS

To what status to auto assign when running `jjic`, to disable enter empty value (`""`)

#### Default value

```bash
JIRA_AUTO_STATUS='In Progress'
```

### JIRA_ISSUE_COMPONENT

To what component to auto assign when running `jjic`

#### Default value

NONE

### JIRA_EPIC_MAP

map to automatically asian git projects to epic tasks

to set up add the variable `JIRA_EPIC_MAP` like so:

```bash
declare -A JIRA_EPIC_MAP=(
  ["<git remote url>"]="<jira issue id>"
  ["<other git remote url>"]="<other jira issue id>"
  # Example
  # ["https://github.com/omribarzik/jira.plugin.zsh.git"]="DV-477"
)
```

> make sure to use the full git remote url (you can get it by running ``git remote get-url origin`` inside your git project)

#### Default value

None

### JIRA_TYPE_MAP

map to automatically asian jira epics types to task type

to set up add the variable `JIRA_TYPE_MAP` like so

```bash
declare -A JIRA_TYPE_MAP=(
  ["<epic type>"]="<jira task type>"
  ["<other epic type>"]="<other jira task type>"
  # Example
  # ["Epic"]="Task"
  # ["Lifter"]="Sub-task"
)
```

#### Default value

```bash
declare -A JIRA_TYPE_MAP=(
  ["Epic"]="Task"
  ["Lifter"]="Sub-task"
)
```
