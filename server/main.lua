local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('jobcreator:createJob')
AddEventHandler('jobcreator:createJob', function(jobLabel, jobName)
    local src = source

    if jobLabel and jobName and jobLabel ~= "" and jobName ~= "" then
        local query = 'INSERT INTO basjobs (job_label, job_name) VALUES (@label, @name)'
        local parameters = {
            ['@label'] = jobLabel,
            ['@name'] = jobName
        }

        MySQL.Async.execute(query, parameters, function(affectedRows)
            if affectedRows > 0 then
                TriggerClientEvent('jobcreator:jobCreated', src, true, jobLabel, jobName)
            else
                TriggerClientEvent('jobcreator:jobCreated', src, false)
                print("Error creating job")
            end
        end)
    else
        TriggerClientEvent('jobcreator:jobCreated', src, false)
    end
end)
RegisterServerEvent('jobcreator:addRankToJob')
AddEventHandler('jobcreator:addRankToJob', function(jobName, joblabel, rankLabel, rankName, rankGrade, rankSalary)
    local src = source
    if not src then
        print("Error: source is nil!")
        return
    end
    if jobName == nil or rankLabel == nil or rankName == nil or rankGrade == nil or rankSalary == nil then
        print("Error: One or more arguments are nil!")
        TriggerClientEvent('jobcreator:rankAdded', src, false)
        return
    end

    MySQL.Async.execute('INSERT INTO basjob_ranks (job_name, job_label, label, name, grade, salary) VALUES (@jobName, @joblabel, @label, @name, @grade, @salary)', {
        ['@jobName'] = jobName,
        ['@joblabel'] = joblabel,
        ['@label'] = rankLabel,
        ['@name'] = rankName,
        ['@grade'] = rankGrade,
        ['@salary'] = rankSalary
    }, function(affectedRows)
        if affectedRows > 0 then
            TriggerEvent('pushJobs:QBCore')
            TriggerClientEvent('jobcreator:rankAdded', src, true, rankLabel, rankName)
        else
            TriggerClientEvent('jobcreator:rankAdded', src, false)
        end
    end)
end)

QBCore.Functions.CreateCallback('jobcreator:getRanksForJob', function(source, cb, jobName)
    MySQL.Async.fetchAll('SELECT * FROM basjob_ranks WHERE job_name = @jobName', {
        ['@jobName'] = jobName
    }, function(ranks)
        cb(ranks)  
    end)
end)
QBCore.Functions.CreateCallback('jobcreator:getJobs', function(source, cb)
    local jobs = {}
    MySQL.Async.fetchAll('SELECT job_name, job_label FROM basjob_ranks GROUP BY job_name, job_label', {}, function(results)
        for _, result in ipairs(results) do
            table.insert(jobs, {
                job_name = result.job_name,
                job_label = result.job_label
            })
        end
        cb(jobs)
    end)
end)


RegisterServerEvent('jobcreator:getJobs')
AddEventHandler('jobcreator:getJobs', function()
    local src = source
    local jobs = {}

    MySQL.Async.fetchAll('SELECT job_label, job_name FROM basjobs', {}, function(result)
        for _, job in ipairs(result) do
            table.insert(jobs, {
                label = job.job_label,
                name = job.job_name
            })
        end
        TriggerClientEvent('jobcreator:showJobs', src, jobs)
    end)
end)

RegisterServerEvent('jobcreator:savePublicMarker', function(data)
    local src = source
    local markerType = data[1]
    local label = data[2]
    local coordX = data[3]
    local coordY = data[4]
    local coordZ = data[5]
    local jobName = data[6]
    local minGrade = data[7]
    local specificGrades = data[8]
    local scaleX = data[9]
    local scaleY = data[10]
    local scaleZ = data[11]
    local markerCoordX = data[12]
    local markerCoordY = data[13]
    local markerCoordZ = data[14]
    local markerColor = data[15]
    local capacity = data[16]
    local blipEnabled = data[17]
    local blipSprite = data[18]
    local blipColor = data[19]
    local blipScale = data[20]
    local npcEnabled = data[21]
    local npcModel = data[22]
    local npcHeading = data[23]
    local objectEnabled = data[24]
    local objectModel = data[25]
    local objectPitch = data[26]
    local objectRoll = data[27]
    local objectYaw = data[28]

    MySQL.insert('INSERT INTO public_markers (marker_type, label, coord_x, coord_y, coord_z, job_name, min_grade, specific_grades, scale_x, scale_y, scale_z, marker_coord_x, marker_coord_y, marker_coord_z, marker_color, capacity, blip_enabled, blip_sprite, blip_color, blip_scale, npc_enabled, npc_model, npc_heading, object_enabled, object_model, object_pitch, object_roll, object_yaw) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        markerType, label, coordX, coordY, coordZ, jobName, minGrade, specificGrades and 1 or 0,
        scaleX, scaleY, scaleZ, markerCoordX, markerCoordY, markerCoordZ, markerColor, capacity,
        blipEnabled and 1 or 0, blipSprite, blipColor, blipScale,
        npcEnabled and 1 or 0, npcModel, npcHeading,
        objectEnabled and 1 or 0, objectModel, objectPitch, objectRoll, objectYaw
    })
end)


CreateThread(function()
    TriggerEvent('pushJobs:QBCore')
end)

RegisterNetEvent('pushJobs:QBCore', function()
    local jobs = {}

    MySQL.Async.fetchAll('SELECT DISTINCT job_name FROM basjob_ranks', {}, function(results)
        if results and #results > 0 then
            for _, result in ipairs(results) do
                local jobName = result.job_name

                MySQL.Async.fetchAll('SELECT * FROM basjob_ranks WHERE job_name = @jobName', {
                    ['@jobName'] = jobName
                }, function(ranks)
                    if ranks and #ranks > 0 then
                        local jobLabel = ranks[1].job_label
                        print("Job Label: " .. jobLabel)
                        local grades = {}

                        for _, rank in ipairs(ranks) do
                            grades[tostring(rank.grade)] = {
                                name = rank.label,
                                payment = rank.salary
                            }
                        end

                        local job = {
                            label = jobLabel,
                            defaultDuty = true,
                            offDutyPay = false,
                            grades = grades
                        }

                        print("Job added: " .. jobName)
                        exports['qb-core']:AddJob(jobName, job)
                    end
                end)
            end
        else
            print("No jobs found in basjob_ranks.")
        end
    end)

end)

QBCore.Functions.CreateCallback('jobcreator:getPublicMarkers', function(_, cb)
    local markers = MySQL.query.await('SELECT * FROM public_markers')
    cb(markers)
end)
