-- PagerDuty Integration
-- Emily Eicher
-- An integration with Q-SYS and PagerDuty API

-- Constants
local json = require("rapidjson")
local url = 'https://api.pagerduty.com/incidents'
local poll_incidents = Timer.New()
local grey = 'FFFFFF00'
local red = 'Red'
local green = 'Green'

-- Variables
local html_url = ''
local sort = 'urgency:DESC'

-- Aliases
local cre_incident = Controls.cre_incident
local ack_incident = Controls.ack_incident
local res_incident = Controls.res_incident
local triggered_incidents = Controls.triggered_incidents
local acknowledged_incidents = Controls.acknowledged_incidents
local details = Controls.details
local title = Controls.title
local feedback = Controls.feedback
local urgency = Controls.urgency
local selected_incident_details = Controls.selected_incident_details
local selected_incident_url = Controls.selected_incident_url
local note = Controls.note
local submit_response = Controls.submit_response
local chat = Controls.chat
local sort_by = Controls.sort_by
local room = Controls.room
local username = Controls.username
local service_id = Controls.service_id
local api_key = Controls.api_key
local devices = Controls.devices
local issues = Controls.issues
local types = Controls.types

-- Tables
local triggered_incidents_tab = {}
local acknowledged_incidents_tab = {}
local chats_tab = {}
local devices_tab = {}
local selected_devices = {}
local triggered_incident_map = {}
local acknowledged_incident_map = {}
local sort_by_map = {
    ['Urgency - High to Low'] = 'urgency:DESC',
    ['Urgency - Low to High'] = 'urgency:ASC',
    ['Newest'] = 'created_at:DESC',
    ['Oldest'] = 'created_at:ASC'
}
acknowledged_incidents.Choices = {}
triggered_incidents.Choices = {}
chat.Choices = {}
urgency.Choices = {'High', 'Low'}
sort_by.Choices = {'Urgency - High to Low', 'Urgency - Low to High', 'Newest', 'Oldest'}
types.Choices = {'Audio', 'Video', 'Camera', 'Conferencing', 'Control', 'Microphone','Touch Screen', 'Other'}

issues_tab = {
  Core = {},
  Conferencing = {'Cannot start a conference call'},
  Control = {},
  Audio = {'Audio is not working in the room', 'The wrong audio device is coming into the room', 'The audio sounds bad in the room', 'Other'},
  Camera = {'Image is poor quality', 'Camera is not facing the right direction', 'Camera is not showing up on call', 'Other'},
  Video = {'Display is not on', 'Source is not detected on display', 'Image is poor quality', 'Other'},
  Touch = {'Touch screen is offline', 'Touch screen is not responding', 'A control on the touch screen is not working properly', 'Other'},
  Microphone = {'The microphone LED is flashing', 'The microphone audio is not working', 'We cannot select the microphone on the call', 'The microphone sounds bad', 'Other'}
}

-- Initialize Fields
acknowledged_incidents.String = ''
triggered_incidents.String = ''
selected_incident_url.String = ''
selected_incident_details.String = ''
note.String = ''
sort_by.String = 'Urgency - High to Low'
devices.String = ''
issues.String = ''
details.String = ''
urgency.String = ''
types.String = ''
devices.Choices = {}
issues.Choices = {}

-- Recursive Print Helper Function
local function recursive_print(object, limit, prefix)
    limit = (limit) or 100;
    prefix = prefix or ""
    if (limit < 1) then
        print("ERROR: Item limit reached.")
        return limit - 1
    end
    local ts = type(object)
    if (ts ~= "table") then
        print(prefix, object)
        return limit - 1
    end
    print(prefix)
    for k, v in pairs(object) do
        limit = recursive_print(v, limit, prefix .. "[" .. tostring(k) .. "]")
        if (limit < 0) then
            break
        end
    end
    return limit
end

--Get Inventory
function get_inventory()
  for k,v in pairs(Design.GetInventory()) do
    print("Inventory: Type:"..v.Type,"Name:"..v.Name,"Loc:"..v.Location,"Model:"..v.Model)
    table.insert(devices_tab, v.Type..' - '..v.Name)
  end
end

function populate_fields()
  clear_field(devices)
  clear_field(issues)
  clear_field(urgency)
  if types.String == 'Other' then 
    devices.Choices = devices_tab
    issues.Choices = {}
  else
    _, j = types.String:find("%s")
    populate_issues(types)
    for k in pairs (selected_devices) do
      selected_devices[k] = nil
    end
    for i,v in pairs(devices_tab) do
      _, j = v:find(types.String)
      local current_choices = v:sub(1, j)
      if j ~= nil then 
        table.insert(selected_devices, v)
      end
    end
    devices.Choices = selected_devices
  end
end

function populate_issues(control)
  _, j = control.String:find("%s")
  if j ~= nil then
    local current_type = control.String:sub(1, j-1)
    issues.Choices = issues_tab[current_type]
  else
    issues.Choices = issues_tab[control.String]
  end
end

types.EventHandler = populate_fields
devices.EventHandler = function() populate_issues(devices) end


-- HTML Call Done Functions

function create_done(tbl, code, d, e)
    local response = json.decode(d)
    local incident_id = response.incident.id
    html_url = response.incident.html_url
    if #incident_id > 0 then
        feedback.String = 'Incident Created'
        feedback.Color = green
        Timer.CallAfter(clear_feedback, 5)
    else
        feedback.String = 'Error when creating incident'
        feedback.Color = red
        Timer.CallAfter(clear_feedback, 5)
    end
    Timer.CallAfter(get_triggered_incidents, 2)
    clear_field(types)
    clear_field(devices)
    clear_field(details)
    clear_field(issues)
    clear_field(urgency)
    Controls.triggered_incidents.String = ''
    Controls.acknowledged_incidents.String = ''
end

function res_ack_done(tbl, code, d, e)
    local response = json.decode(d)
    local status = response.incident.status
    local title = response.incident.title
    if #status > 0 then
        feedback.String = title .. " - Incident " .. string.upper(status)
        feedback.Color = green
        Timer.CallAfter(clear_feedback, 5)
        clear_field(selected_incident_details)
    else
        feedback.String = "Error responding to incident"
        feedback.Color = red
        Timer.CallAfter(clear_feedback, 5)
    end
    Timer.CallAfter(get_triggered_incidents, 2)
end

function get_triggered_done(tbl, code, d, e)
    local get_response = json.decode(d)
    for k in pairs(triggered_incidents_tab) do
        triggered_incidents_tab[k] = nil
    end
    for i, v in pairs(get_response.incidents) do
        table.insert(triggered_incidents_tab, v.title)
        triggered_incident_map[v.title] = v.self
    end
    triggered_incidents.Choices = triggered_incidents_tab
    Timer.CallAfter(get_acknowledged_incidents, 2)
    Timer.CallAfter(get_specific_incident, 4)
end

function get_acknowledged_done(tbl, code, d, e)
    local get_response = json.decode(d)
    for k in pairs(acknowledged_incidents_tab) do
        acknowledged_incidents_tab[k] = nil
    end
    for i, v in pairs(get_response.incidents) do
        table.insert(acknowledged_incidents_tab, v.title)
        acknowledged_incident_map[v.title] = v.self
    end
    acknowledged_incidents.Choices = acknowledged_incidents_tab
end

function get_specific_done(tbl, code, d, e)
    local get_response = json.decode(d)
    if get_response ~= nil then
        selected_incident_details.String = 'Title: ' .. get_response.incident.title .. '\n' .. 'Status: ' ..
        get_response.incident.status .. '\n' .. 'Urgency: ' ..
        get_response.incident.urgency .. '\n' .. 'Details: '..get_response.incident.body.details
        selected_incident_url.String = get_response.incident.html_url
    end
    get_note()
end

function get_note_done(tbl, code, d, e)
    if #triggered_incidents.String > 0 or #acknowledged_incidents.String > 0 then
        local get_response = json.decode(d)
        for k in pairs(chats_tab) do
            chats_tab[k] = nil
        end
        if get_response.notes[1] ~= nil then
            for i, v in pairs(get_response.notes) do
                local chat_resp = v.created_at .. ' ' .. v.content
                table.insert(chats_tab, chat_resp)
                chat.Choices = chats_tab
            end
        else
            chat.Choices = {'There are no notes for this incident.'}
        end
    end
end

function create_note_done(tbl, code, d, e)
    feedback.String = 'Response submitted'
    feedback.Color = green
    Timer.CallAfter(clear_feedback, 5)
end

local function create_incident(data)
    if #url > 0 then
        HttpClient.Upload {
            Url = url,
            Method = "POST",
            Data = json.encode(data),
            Headers = {
                ["Authorization"] = api_key.String,
                ["Accept"] = "application/vnd.pagerduty+json;version=2",
                ["Content-Type"] = "application/json",
                ["From"] = username.String
            },
            EventHandler = create_done
        }
    end
end

-- Respond to Incident
local function res_ack_incident(data)
    if #html_url > 0 then
        HttpClient.Upload {
            Url = html_url,
            Method = "PUT",
            Data = json.encode(data),
            Headers = {
                ["Authorization"] = api_key.String,
                ["id"] = incident_id,
                ["Accept"] = "application/vnd.pagerduty+json;version=2",
                ["Content-Type"] = "application/json",
                ["From"] = username.String
            },
            EventHandler = res_ack_done
        }
    end
end

local function create_note(data)
    if #html_url > 0 then
        HttpClient.Upload {
            Url = html_url .. '/notes',
            Method = "POST",
            Data = json.encode(data),
            Headers = {
                ["Authorization"] = api_key.String,
                ["Accept"] = "application/vnd.pagerduty+json;version=2",
                ["Content-Type"] = "application/json",
                ["From"] = username.String
            },
            EventHandler = create_note_done
        }
    end
end

function get_triggered_incidents()
    HttpClient.Download {
        Url = "https://api.pagerduty.com/incidents?include[]=body?statuses%5B%5D=triggered&sort_by=" .. sort,
        Headers = {
            ["Authorization"] = api_key.String,
            ["Accept"] = "application/vnd.pagerduty+json;version=2",
            ["Content-Type"] = "application/json"
        },
        Timeout = 30,
        EventHandler = get_triggered_done
    }
end

function get_acknowledged_incidents()
    HttpClient.Download {
        Url = "https://api.pagerduty.com/incidents?statuses%5B%5D=acknowledged&sort_by=" .. sort,
        Headers = {
            ["Authorization"] = api_key.String,
            ["Accept"] = "application/vnd.pagerduty+json;version=2",
            ["Content-Type"] = "application/json"
        },
        Timeout = 30,
        EventHandler = get_acknowledged_done
    }
end

function get_specific_incident()
    HttpClient.Download {
        Url = html_url..'?include[]=body',
        Headers = {
            ["Authorization"] = api_key.String,
            ["Accept"] = "application/vnd.pagerduty+json;version=2",
            ["Content-Type"] = "application/json"
        },
        Timeout = 30,
        EventHandler = get_specific_done
    }
end

function get_note()
    HttpClient.Download {
        Url = html_url .. '/notes',
        Headers = {
            ["Authorization"] = api_key.String,
            ["Accept"] = "application/vnd.pagerduty+json;version=2",
            ["Content-Type"] = "application/json"
        },
        Timeout = 30,
        EventHandler = get_note_done
    }
end

local function create_note_data()
    local data = {
        note = {
            content = note.String
        }
    }
    create_note(data)
end

-- Button Event Handlers

cre_incident.EventHandler = function()
  local details = issues.String..'\r'..details.String
    if #types.String > 0 and #urgency.String > 0 then
        local data = {
            incident = {
                type = "incident",
                title = room.String..' - '..devices.String..' - '..issues.String,
                service = {
                    id = service_id.String,
                    type = "service_reference"
                },
                urgency = string.lower(urgency.String),
                body = {
                    type = "incident_body",
                    details = details
                }
            }
        }
        create_incident(data)
    else
        feedback.String = 'Please provide the information before creating an incident.'
        feedback.Color = 'Red'
        Timer.CallAfter(clear_feedback, 5)

    end
end

local function res_ack(option)
    local data = {
        incident = {
            type = "incident_reference",
            status = option
        }
    }
    res_ack_incident(data)
    clear_field(note)
end

ack_incident.EventHandler = function()
    res_ack('acknowledged')
end

res_incident.EventHandler = function()
    res_ack('resolved')
end

triggered_incidents.EventHandler = function()
    html_url = triggered_incident_map[triggered_incidents.String]
    clear_field(acknowledged_incidents)
    get_specific_incident()
end

acknowledged_incidents.EventHandler = function()
    html_url = acknowledged_incident_map[acknowledged_incidents.String]
    clear_field(triggered_incidents)
    get_specific_incident()
end

sort_by.EventHandler = function()
    sort = sort_by_map[sort_by.String]
    get_triggered_incidents()
    get_acknowledged_incidents()
end

submit_response.EventHandler = function()
    if #note.String > 0 then
        create_note_data()
        clear_field(note)
    else
        feedback.String = 'Please type a response before submitting'
        feedback.Color = red
        Timer.CallAfter(clear_feedback, 5)
    end
end

function clear_feedback()
    feedback.String = ''
    feedback.Color = grey
end

function clear_field(field)
    field.String = ''
end

function start_poll()
    poll_incidents:Start(6)
end

get_inventory()
poll_incidents.EventHandler = get_triggered_incidents
get_triggered_incidents()
start_poll()