local QBCore = exports['qb-core']:GetCoreObject()
local jobLabel = nil
local jobName = nil
local function refreshManageJobsContext()
    TriggerServerEvent('jobcreator:getJobs')

    lib.registerContext({
        id = 'jobcreator_manage_jobs',
        title = 'Manage Jobs',
        options = {
            {
                title = 'Create New Job',
                description = 'Create a new job for the system',
                icon = 'plus-circle',
                menu = 'jobcreator_create_job'
            }
        }
    })
end

local function refreshJobCreationContext()
    lib.registerContext({
        id = 'jobcreator_create_job',
        title = 'Create New Job',
        options = {
            {
                title = 'New Job Label',
                description = jobLabel and ('Current Label: ' .. jobLabel) or 'Enter a label for the new job',
                icon = 'tag',
                onSelect = function()
                    local input = lib.inputDialog('New Job Label', {
                        {type = 'input', label = 'Enter Job Label', placeholder = 'Job label', required = true}
                    }, {
                        allowCancel = true
                    })

                    if input then
                        jobLabel = input[1] 
                        refreshJobCreationContext() 
                        lib.showContext('jobcreator_create_job') 
                    end
                end
            },
            {
                title = 'New Job Name',
                description = jobName and ('Current Name: ' .. jobName) or 'Enter a name for the new job',
                icon = 'user-tie',
                onSelect = function()
                    local input = lib.inputDialog('New Job Name', {
                        {type = 'input', label = 'Enter Job Name', placeholder = 'Job name', required = true}
                    }, {
                        allowCancel = true
                    })

                    if input then
                        jobName = input[1] 
                        refreshJobCreationContext() 
                        lib.showContext('jobcreator_create_job')
                    end
                end
            },
            {
                title = 'Confirm',
                description = 'Proceed to confirm the job creation',
                icon = 'check-circle',
                disabled = not (jobLabel and jobName),
                onSelect = function()
                    TriggerServerEvent('jobcreator:createJob', jobLabel, jobName)
                end
            }
        }
    })
end

refreshJobCreationContext()

lib.registerContext({
    id = 'jobcreator_main',
    title = 'Job Creator',
    options = {
        {
            title = 'Jobs',
            description = 'Manage and create new jobs',
            icon = 'briefcase',
            menu = 'jobcreator_jobs'
        },
        {
            title = 'Public Markers',
            description = 'Create public map markers',
            icon = 'map-marker-alt',
            onSelect = function()
                TriggerEvent('jobcreator:publicMarkers')
            end
        },        
        {
            title = 'Settings',
            description = 'Configure job creator settings',
            icon = 'cog',
            menu = 'jobcreator_settings'
        }
    }
})

lib.registerContext({
    id = 'jobcreator_jobs',
    title = 'Manage Jobs',
    options = {
        {
            title = 'Manage Jobs',
            description = 'View and manage existing jobs',
            icon = 'tasks',
            onSelect = function()
                refreshManageJobsContext()
            end
        },
        {
            title = 'Create New Job',
            description = 'Create a new job for the system',
            icon = 'plus-circle',
            menu = 'jobcreator_create_job'
        }
    }
})

RegisterNetEvent('jobcreator:publicMarkers', function()
    local coords = GetEntityCoords(cache.ped)

    QBCore.Functions.TriggerCallback('jobcreator:getJobs', function(jobs)
        if not jobs then
            print("No jobs found.")
            return
        end

        local jobOptions = {}
        for _, job in ipairs(jobs) do
            table.insert(jobOptions, {label = job.job_label, value = job.job_name})
        end

        local input = lib.inputDialog('Create Public Marker', {
            {type = 'select', label = 'Marker Type', required = true, options = {
                {label = 'Stash', value = 'stash'},
                {label = 'Armory', value = 'armory'},
                {label = 'Safe', value = 'safe'},
                {label = 'Job Outfit', value = 'job_outfit'}
            }},
            {type = 'input', label = 'Label', required = true},
            {type = 'number', label = 'X', icon = 'x', default = coords.x},
            {type = 'number', label = 'Y', icon = 'y', default = coords.y},
            {type = 'number', label = 'Z', icon = 'z', default = coords.z},
            {type = 'select', label = 'Job', options = jobOptions},
            {type = 'number', label = 'Minimum Grade', default = 0},
            {type = 'checkbox', label = 'Use Specific Grades Instead?', default = false},
            {type = 'number', label = 'Marker Scale X', default = 0.5},
            {type = 'number', label = 'Marker Scale Y', default = 0.5},
            {type = 'number', label = 'Marker Scale Z', default = 0.5},
            {type = 'number', label = 'Coords X', default = coords.x},
            {type = 'number', label = 'Coords Y', default = coords.y},
            {type = 'number', label = 'Coords Z', default = coords.z},
            {type = 'color', label = 'Marker Color', default = '#ffffff'},
            {type = 'slider', label = 'Capacity (0 - 1)', min = 0.0, max = 1.0, step = 0.1, default = 1.0},
            {type = 'checkbox', label = 'Enable Map Blip?', default = false},
            {type = 'number', label = 'Blip Sprite', default = 1},
            {type = 'number', label = 'Blip Color', default = 1},
            {type = 'number', label = 'Blip Scale', default = 1.0},
            {type = 'checkbox', label = 'Enable Standing NPC?', default = false},
            {type = 'input', label = 'NPC Model', default = 's_m_m_security_01'},
            {type = 'number', label = 'NPC Heading', default = 0.0},
            {type = 'checkbox', label = 'Enable Object?', default = false},
            {type = 'input', label = 'Object Model', default = 'prop_box_wood01a'},
            {type = 'number', label = 'Object Pitch', default = 0.0},
            {type = 'number', label = 'Object Roll', default = 0.0},
            {type = 'number', label = 'Object Yaw', default = 0.0}
        })

        if not input then return end

        print(json.encode(input, {indent = true}))
        TriggerServerEvent('jobcreator:savePublicMarker', input)
        Wait(1000)
        getPublicMarkers()
    end)
end)
local function DrawText3D(coords, text)
    local onScreen, _x, _y = World3dToScreen2d(coords.x, coords.y, coords.z)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    DrawText(_x, _y)
end

function getPublicMarkers()
    QBCore.Functions.TriggerCallback('jobcreator:getPublicMarkers', function(markers)
        for _, m in pairs(markers) do
            local marker = {
                type = m.marker_type,
                label = m.label,
                job = m.job_name,
                minGrade = m.min_grade,
                specificGrades = m.specific_grades == 1,
                scale = vec3(m.scale_x, m.scale_y, m.scale_z),
                coords = vec3(m.marker_coord_x, m.marker_coord_y, m.marker_coord_z),
                color = m.marker_color,
                capacity = m.capacity,
                blip = {
                    enabled = m.blip_enabled,
                    sprite = m.blip_sprite,
                    color = m.blip_color,
                    scale = m.blip_scale
                },
                npc = {
                    enabled = m.npc_enabled == 1,
                    model = m.npc_model,
                    heading = m.npc_heading
                },
                object = {
                    enabled = m.object_enabled == 1,
                    model = m.object_model,
                    pitch = m.object_pitch,
                    roll = m.object_roll,
                    yaw = m.object_yaw
                }
            }
            if marker.blip.enabled then
                local blip = AddBlipForCoord(marker.coords.x, marker.coords.y, marker.coords.z)
                SetBlipSprite(blip, marker.blip.sprite)
                SetBlipScale(blip, marker.blip.scale)
                SetBlipColour(blip, marker.blip.color)
                SetBlipDisplay(blip, 2)
                SetBlipAsShortRange(blip, true)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString(marker.label)
                EndTextCommandSetBlipName(blip)
            end
            
            if marker.type == "stash" then
                CreateThread(function()
                    while true do
                        local sleep = 1000
                        local playerCoords = GetEntityCoords(PlayerPedId())
                        local dist = #(playerCoords - marker.coords)
                        if dist < 20.0 then
                            sleep = 0
                            DrawMarker(2, marker.coords.x, marker.coords.y, marker.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                                marker.scale.x, marker.scale.y, marker.scale.z,
                                tonumber(marker.color:sub(2, 3), 16),
                                tonumber(marker.color:sub(4, 5), 16),
                                tonumber(marker.color:sub(6, 7), 16),
                                155, false, true, 2, false, nil, nil, false)
                            if dist < 1.5 then
                                DrawText3D(marker.coords, "~g~[E]~s~ Open Stash: " .. marker.label)
                                if IsControlJustPressed(0, 38) then
                                    TriggerServerEvent("inventory:server:OpenInventory", "stash", marker.label)
                                end
                            end
                        end
                        Wait(sleep)
                    end
                end)
            end
        end
    end)
end

CreateThread(function()
    getPublicMarkers()
end)

RegisterNetEvent('jobcreator:showJobs')
AddEventHandler('jobcreator:showJobs', function(jobs)
    local jobOptions = {}

    for _, job in ipairs(jobs) do
        table.insert(jobOptions, {
            title = job.label,
            description = 'Job Name: ' .. job.name,
            icon = 'user-tie',
            onSelect = function()
                QBCore.Functions.TriggerCallback('jobcreator:getRanksForJob', function(ranks)
                    local rankOptions = {}
                    for _, rank in ipairs(ranks) do
                        table.insert(rankOptions, {
                            title = rank.label,
                            description = 'Rank Name: ' .. rank.name .. ' | Grade: ' .. rank.grade .. ' | Salary: ' .. rank.salary,
                            icon = 'user-tag',
                            onSelect = function()
                                lib.notify({
                                    title = 'Rank Selected',
                                    description = 'You selected the rank: ' .. rank.label,
                                    type = 'success'
                                })
                            end
                        })
                    end

                    table.insert(rankOptions, {
                        title = 'Add Rank',
                        description = 'Add a new rank to this job',
                        icon = 'plus',
                        onSelect = function()
                            local input = lib.inputDialog('Add Rank to ' .. job.label, {
                                {type = 'input', label = 'Enter Rank Label', placeholder = 'Rank Label', required = true},
                                {type = 'input', label = 'Enter Rank Name', placeholder = 'Rank Name', required = true},
                                {type = 'number', label = 'Enter Rank Grade', placeholder = 'Rank Grade (Number)', required = true},
                                {type = 'number', label = 'Enter Rank Salary', placeholder = 'Rank Salary (Number)', required = true}
                            })

                            if input then
                                local rankLabel = input[1]
                                local rankName = input[2]
                                local rankGrade = tonumber(input[3])
                                local rankSalary = tonumber(input[4])

                                if rankGrade and rankSalary then
                                    TriggerServerEvent('jobcreator:addRankToJob', job.name, job.label, rankLabel, rankName, rankGrade, rankSalary)
                                else
                                    lib.notify({
                                        title = 'Invalid Input',
                                        description = 'Please ensure that Grade and Salary are numbers.',
                                        type = 'error'
                                    })
                                end
                            end
                        end
                    })

                    lib.registerContext({
                        id = 'jobcreator_manage_ranks',
                        title = 'Manage Ranks for ' .. job.label,
                        options = rankOptions
                    })

                    lib.showContext('jobcreator_manage_ranks')
                end, job.name) 
            end
        })
    end

    lib.registerContext({
        id = 'jobcreator_manage_jobs',
        title = 'Manage Jobs',
        options = jobOptions
    })

    lib.showContext('jobcreator_manage_jobs')
end)

RegisterNetEvent('jobcreator:rankAdded')
AddEventHandler('jobcreator:rankAdded', function(success, rankLabel, rankName)
    if success then
        lib.notify({
            title = 'Rank Added',
            description = 'Rank successfully added: ' .. rankLabel .. ' - ' .. rankName,
            type = 'success'
        })
    else
        lib.notify({
            title = 'Rank Addition Failed',
            description = 'Failed to add rank.',
            type = 'error'
        })
    end
end)

RegisterNetEvent('jobcreator:jobCreated')
AddEventHandler('jobcreator:jobCreated', function(success, jobLabel, jobName)
    if success then
        lib.notify({
            title = 'Job Created',
            description = 'Job successfully created: ' .. jobLabel .. ' - ' .. jobName,
            type = 'success'
        })
    else
        lib.notify({
            title = 'Job Creation Failed',
            description = 'Failed to create job.',
            type = 'error'
        })
    end
end)


RegisterCommand('jobcreator', function()
    lib.showContext('jobcreator_main')
end)
