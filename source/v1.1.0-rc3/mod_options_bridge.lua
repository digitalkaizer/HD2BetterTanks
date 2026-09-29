-- HD2-Addon: mods/digitalkaizer/better_tanks_mod_options
-- HD2 Better Tanks v1.1.0 RC3
-- Optional integration with CowboyBingus Mod Options Menu API 1.
-- Better Tanks does NOT require Mod Options Menu; this bridge becomes active only when it is present.

if rawget(_G,'DigitalKaizerBetterTanksModOptions') then
    return rawget(_G,'DigitalKaizerBetterTanksModOptions')
end

local Common=require('mods/digitalkaizer/better_tanks_common')

local state={
    version='better-tanks-v1.1.0-rc3-mod-options',
    registered=false,
    failed=false,
    frames=0,
    pending={},
    pending_count=0,
    writes=0,
    status='waiting_for_mod_options_menu',
}
rawset(_G,'DigitalKaizerBetterTanksModOptions',state)

local function log(msg)
    state.status=tostring(msg)
    Common.log('ModOptions',state.status)
end

local function format_number(value,integer)
    if integer then
        return tostring(math.floor(value+0.5))
    end
    local s=string.format('%.3f',value)
    s=s:gsub('0+$',''):gsub('%.$','')
    if s=='-0' then s='0' end
    return s
end

local function flush_pending()
    if state.pending_count==0 then return true end
    if not io or not io.open then return false,'Lua file I/O unavailable' end

    local f=io.open(Common.config_path,'rb')
    if not f then return false,'Better Tanks config is not available yet' end
    local text=f:read('*a') or ''
    f:close()

    local newline=text:find('\r\n',1,true) and '\r\n' or '\n'
    text=text:gsub('\r\n','\n')
    if text~='' and text:sub(-1)~='\n' then text=text..'\n' end

    local lines={}
    for line in text:gmatch('(.-)\n') do lines[#lines+1]=line end

    local found={}
    for i,line in ipairs(lines) do
        local key=line:match('^%s*([%w_]+)%s*=')
        local p=key and state.pending[key]
        if p and not found[key] then
            local prefix,old,suffix=line:match('^(%s*[%w_]+%s*=%s*)([%+%-]?[%d%.]+)(.*)$')
            if prefix and old then
                lines[i]=prefix..format_number(p.value,p.integer)..(suffix or '')
                found[key]=true
            end
        end
    end

    local missing={}
    for key,_ in pairs(state.pending) do
        if not found[key] then missing[#missing+1]=key end
    end
    table.sort(missing)
    if #missing>0 and (#lines==0 or lines[#lines]~='') then lines[#lines+1]='' end
    for _,key in ipairs(missing) do
        local p=state.pending[key]
        lines[#lines+1]=key..'='..format_number(p.value,p.integer)
    end

    local out=table.concat(lines,newline)
    if out=='' or out:sub(-#newline)~=newline then out=out..newline end

    local w=io.open(Common.config_path,'wb')
    if not w then return false,'could not open Better Tanks config for writing' end
    local ok,why=pcall(function() w:write(out); w:flush() end)
    w:close()
    if not ok then return false,tostring(why) end

    local count=state.pending_count
    state.pending={}
    state.pending_count=0
    state.writes=state.writes+count
    log('saved '..tostring(count)..' option change(s) to '..Common.config_path..'; restart HD2 for guaranteed application')
    return true
end

local function queue_value(key,value,integer)
    if not state.pending[key] then state.pending_count=state.pending_count+1 end
    state.pending[key]={value=value,integer=integer}
end

local BASTION='BETTER TANKS - BASTION'
local STORM='BETTER TANKS - STORM'

local OPTIONS={
    {key='bastion_main_health',mod=BASTION,label='Main Health',min=1,max=1000000,step=1,integer=true,description='Bastion main hull health. Stock: 8000. Restart HD2 after changing.'},
    {key='bastion_constitution',mod=BASTION,label='Constitution',min=0,max=1000000,step=1,integer=true,description='Negative-health pool after normal health is depleted. Stock: 70000. Restart required.'},
    {key='bastion_constitution_decay',mod=BASTION,label='Constitution Decay / sec',min=-1000000,max=1000000,step=1,description='Constitution change per second. Negative values drain it. Stock: -10000. Restart required.'},
    {key='bastion_frontal_armor',mod=BASTION,label='Frontal Armor',min=0,max=10,step=1,integer=true,description='Armor value for selected frontal zones 0,1,2,26. Stock: AV4. Restart required.'},
    {key='bastion_stowage_armor',mod=BASTION,label='Stowage Armor',min=0,max=10,step=1,integer=true,description='Armor value for stowage/lunch-box zones 6-11. Stock: AV2. Restart required.'},
    {key='bastion_side_skirt_armor',mod=BASTION,label='Side Skirt Armor',min=0,max=10,step=1,integer=true,description='Armor value for side-skirt zones 16-23. Stock: AV4. Restart required.'},
    {key='bastion_structural_av4_armor',mod=BASTION,label='Structural Armor',min=0,max=10,step=1,integer=true,description='Armor for additional structural AV4 zones. Stock: AV4. Exact geometry labels are not fully confirmed.'},
    {key='bastion_stowage_main_transfer',mod=BASTION,label='Stowage Main Transfer',min=0,max=1,step=0.01,description='Fraction of stowage-zone damage transferred to main hull. 0=0%, 1=100%. Stock: 0. Restart required.'},
    {key='bastion_side_skirt_main_transfer',mod=BASTION,label='Side Skirt Main Transfer',min=0,max=1,step=0.01,description='Fraction of side-skirt damage transferred to main hull. Stock: 1.00. Restart required.'},
    {key='bastion_other_main_transfer',mod=BASTION,label='Other Main Transfer',min=0,max=1,step=0.01,description='Main-health transfer for other configured structural zones. Stock: 1.00. Restart required.'},
    {key='bastion_explosive_damage_taken',mod=BASTION,label='Explosive Damage Taken',min=0,max=1,step=0.01,description='Fraction of explosive damage taken. 0.40 means 40% taken / 60% resistance. Stock: 0.40.'},
    {key='bastion_acceleration',mod=BASTION,label='Acceleration',min=0,max=1000,step=0.1,gap=true,description='VehicleMotion acceleration. Stock: 10.0. Restart required.'},
    {key='bastion_steering_response',mod=BASTION,label='Steering Response',min=0,max=1000,step=0.1,description='Steering input ramp rate. Stock: 2.25. Restart required.'},
    {key='bastion_throttle_response',mod=BASTION,label='Throttle Response',min=0,max=1000,step=0.1,description='Writes both internal throttle ramp fields. Stock fields: 4.0 / 5.0. Restart required.'},
    {key='bastion_brake_response',mod=BASTION,label='Brake Response',min=0,max=1000,step=0.1,description='Writes both internal brake ramp fields. Stock fields: 10.0 / 5.0. Restart required.'},
    {key='bastion_unknown_tracked_coefficient_1',mod=BASTION,label='Track Coefficient 1',min=0,max=1000,step=0.1,description='Experimental VehicleTracks coefficient. Stock: 1. Exact function is not confirmed.'},
    {key='bastion_unknown_tracked_coefficient_2',mod=BASTION,label='Track Coefficient 2',min=0,max=1000,step=0.1,description='Experimental VehicleTracks coefficient. Stock: 22. Exact function is not confirmed.'},
    {key='bastion_unknown_tracked_coefficient_3',mod=BASTION,label='Track Coefficient 3',min=0,max=1000,step=0.1,description='Experimental VehicleTracks coefficient. Stock: 3. Exact function is not confirmed.'},
    {key='bastion_unknown_tracked_coefficient_4',mod=BASTION,label='Track Coefficient 4',min=0,max=1000,step=0.1,description='Experimental track coefficient. Stock: 8. Testing indicates it strongly affects turning when raised.'},
    {key='bastion_unknown_tracked_coefficient_5',mod=BASTION,label='Track Coefficient 5',min=0,max=1000,step=0.1,description='Experimental track coefficient. Stock: 8. Testing indicates it strongly affects turning when raised.'},
    {key='tracked_clutch_delay_seconds',mod=BASTION,label='Shared Clutch Delay',min=0,max=10,step=0.05,description='Shared tracked-vehicle forward/neutral/reverse clutch delay. Stock tank value is about 0.4 sec. Restart required.'},
    {key='tracked_top_speed_scale',mod=BASTION,label='Shared Top Speed Scale',min=0.5,max=2,step=0.01,description='Shared Havok gearing scale with matching torque compensation. 1.0=stock. Restart required.'},
    {key='tracked_driving_turn_scale',mod=BASTION,label='Shared Driving Turn Scale',min=0.5,max=2,step=0.01,description='Shared Havok moving-turn steering envelope. 1.0=stock. Neutral/pivot turn cap is not directly changed.'},
    {key='bastion_cannon_total_shells',mod=BASTION,label='Cannon Total Shells',min=1,max=1000,step=1,integer=true,gap=true,description='Total cannon shells including one loaded shell. Stock game total is 31. Restart required for guaranteed application.'},
    {key='bastion_hmg_ammo',mod=BASTION,label='HMG Ammo',min=1,max=100000,step=1,integer=true,description='Bastion coax/HMG ammunition. Stock: 2000. Better Tanks HUD compatibility follows this value after restart.'},
    {key='bastion_cannon_rpm',mod=BASTION,label='Cannon RPM',min=1,max=600,step=1,description='Main cannon fire rate. Stock: 12 RPM. Restart required.'},
    {key='bastion_hmg_rpm',mod=BASTION,label='HMG RPM',min=1,max=3000,step=1,description='HMG fire rate. Stock: 600 RPM. Restart required.'},
    {key='bastion_cannon_reload_seconds',mod=BASTION,label='Cannon Reload Seconds',min=0.1,max=20,step=0.1,description='Main cannon reload duration. Stock: 4.0 sec. Lower is faster. Restart required.'},
    {key='bastion_cooldown_seconds',mod=BASTION,label='Stratagem Cooldown Seconds',min=1,max=86400,step=1,gap=true,description='Base Bastion stratagem cooldown. Stock: 780 sec. Restart required.'},
    {key='storm_main_health',mod=STORM,label='Main Health',min=1,max=1000000,step=1,integer=true,description='Storm/Maelstrom main hull health. Stock: 8000. Restart HD2 after changing.'},
    {key='storm_constitution',mod=STORM,label='Constitution',min=0,max=1000000,step=1,integer=true,description='Negative-health pool after normal health is depleted. Stock: 70000. Restart required.'},
    {key='storm_constitution_decay',mod=STORM,label='Constitution Decay / sec',min=-1000000,max=1000000,step=1,description='Constitution change per second. Negative values drain it. Stock: -10000. Restart required.'},
    {key='storm_frontal_armor',mod=STORM,label='Frontal Armor',min=0,max=10,step=1,integer=true,description='Armor value for selected frontal zones 0,1,2,26. Stock: AV4. Restart required.'},
    {key='storm_stowage_armor',mod=STORM,label='Stowage Armor',min=0,max=10,step=1,integer=true,description='Armor value for stowage zones 6-11. Stock: AV2. Restart required.'},
    {key='storm_side_skirt_armor',mod=STORM,label='Side Skirt Armor',min=0,max=10,step=1,integer=true,description='Armor value for side-skirt zones 16-23. Stock: AV4. Restart required.'},
    {key='storm_structural_av4_armor',mod=STORM,label='Structural Armor',min=0,max=10,step=1,integer=true,description='Armor for additional structural AV4 zones. Stock: AV4. Exact geometry labels are not fully confirmed.'},
    {key='storm_stowage_main_transfer',mod=STORM,label='Stowage Main Transfer',min=0,max=1,step=0.01,description='Fraction of stowage-zone damage transferred to main hull. Stock: 0. Restart required.'},
    {key='storm_side_skirt_main_transfer',mod=STORM,label='Side Skirt Main Transfer',min=0,max=1,step=0.01,description='Fraction of side-skirt damage transferred to main hull. Stock: 1.00. Restart required.'},
    {key='storm_other_main_transfer',mod=STORM,label='Other Main Transfer',min=0,max=1,step=0.01,description='Main-health transfer for other configured structural zones. Stock: 1.00. Restart required.'},
    {key='storm_explosive_damage_taken',mod=STORM,label='Explosive Damage Taken',min=0,max=1,step=0.01,description='Fraction of explosive damage taken. Stock: 0.40. Restart required.'},
    {key='storm_acceleration',mod=STORM,label='Acceleration',min=0,max=1000,step=0.1,gap=true,description='VehicleMotion acceleration. Stock: 10.0. Restart required.'},
    {key='storm_steering_response',mod=STORM,label='Steering Response',min=0,max=1000,step=0.1,description='Steering input ramp rate. Stock: 2.25. Restart required.'},
    {key='storm_throttle_response',mod=STORM,label='Throttle Response',min=0,max=1000,step=0.1,description='Writes both internal throttle ramp fields. Stock fields: 4.0 / 5.0. Restart required.'},
    {key='storm_brake_response',mod=STORM,label='Brake Response',min=0,max=1000,step=0.1,description='Writes both internal brake ramp fields. Stock fields: 10.0 / 5.0. Restart required.'},
    {key='storm_unknown_tracked_coefficient_1',mod=STORM,label='Track Coefficient 1',min=0,max=1000,step=0.1,description='Experimental VehicleTracks coefficient. Stock: 1. Exact function is not confirmed.'},
    {key='storm_unknown_tracked_coefficient_2',mod=STORM,label='Track Coefficient 2',min=0,max=1000,step=0.1,description='Experimental VehicleTracks coefficient. Stock: 22. Exact function is not confirmed.'},
    {key='storm_unknown_tracked_coefficient_3',mod=STORM,label='Track Coefficient 3',min=0,max=1000,step=0.1,description='Experimental VehicleTracks coefficient. Stock: 3. Exact function is not confirmed.'},
    {key='storm_unknown_tracked_coefficient_4',mod=STORM,label='Track Coefficient 4',min=0,max=1000,step=0.1,description='Experimental track coefficient. Stock: 8. Testing indicates it strongly affects turning when raised.'},
    {key='storm_unknown_tracked_coefficient_5',mod=STORM,label='Track Coefficient 5',min=0,max=1000,step=0.1,description='Experimental track coefficient. Stock: 8. Testing indicates it strongly affects turning when raised.'},
    {key='storm_main_gun_rounds_per_belt',mod=STORM,label='Gatling Rounds per Belt',min=1,max=100000,step=1,integer=true,gap=true,description='Rounds in each Storm Gatling belt. Stock: 300. Storm weapon runtime can hot-reload this; fresh tank is safest.'},
    {key='storm_main_gun_spare_belts',mod=STORM,label='Gatling Spare Belts',min=0,max=1000,step=1,integer=true,description='Number of spare Gatling belts. Stock: 6. Non-stock values may not be represented correctly by every HUD build.'},
    {key='storm_main_gun_reload_seconds',mod=STORM,label='Gatling Reload Seconds',min=0,max=30,step=0.1,description='Storm Gatling reload duration. Stock: 4.0 sec. 0 uses the game ability default in Better Tanks logic.'},
    {key='storm_main_gun_rpm',mod=STORM,label='Combined Gatling RPM',min=1,max=6000,step=1,description='Combined twin-Gatling fire rate. Stock: 1200 RPM. Fresh tank may be required for guaranteed materialization.'},
    {key='storm_smoke_total',mod=STORM,label='Smoke Total Charges',min=2,max=20000,step=1,integer=true,description='Driver smoke total charges. Stock: 20. Storm runtime can hot-reload active ammo pools.'},
    {key='storm_smoke_delay_seconds',mod=STORM,label='Smoke Delay Seconds',min=0,max=10,step=0.1,description='Delay between smoke launches. Stock: 5.0 sec. Fresh tank may be required for timing changes.'},
    {key='storm_missiles_per_rack',mod=STORM,label='Missiles per Rear Rack',min=1,max=10000,step=1,integer=true,description='Missile capacity PER rear rack. Stock: 10 each / 20 total. Better Tanks patches the shared rocket magazine template.'},
    {key='storm_cooldown_seconds',mod=STORM,label='Stratagem Cooldown Seconds',min=1,max=86400,step=1,gap=true,description='Base Storm/Maelstrom stratagem cooldown. Stock: 780 sec. Restart required.'},
}

local function register_all()
    if state.registered or state.failed then return end
    local menu=rawget(_G,'ModOptionsMenu')
    local cfg=rawget(_G,'DigitalKaizerHD2BetterTanksConfig')
    if type(menu)~='table' or menu.api~=1 or type(menu.register_option)~='function' then return end
    if type(cfg)~='table' then return end

    local counts={}
    for _,s in ipairs(OPTIONS) do counts[s.mod]=(counts[s.mod] or 0)+1 end
    for title,count in pairs(counts) do
        if count>(menu.max_options or 32) then
            state.failed=true
            log(title..' needs '..tostring(count)..' rows but Mod Options Menu allows only '..tostring(menu.max_options or 32))
            return
        end
    end

    for _,entry in ipairs(OPTIONS) do
        local s=entry
        local key=s.key
        local current=cfg[key]
        if type(current)~='number' then
            state.failed=true
            log('missing Better Tanks config value: '..key)
            return
        end

        local id='digitalkaizer.better_tanks.'..key
        local spec={type='slider',label=s.label,mod=s.mod,min=s.min,max=s.max,step=s.step,default=current,gap=s.gap==true,description=s.description}
        local ok,reason=menu.register_option(id,spec)
        if not ok then
            state.failed=true
            log('registration failed for '..key..': '..tostring(reason))
            return
        end

        local set_ok,set_reason=menu.set(id,current)
        if not set_ok then
            state.failed=true
            log('could not synchronize '..key..' from INI: '..tostring(set_reason))
            return
        end

        local cb_ok,cb_reason=menu.on_change(id,function(value)
            queue_value(key,value,s.integer==true)
        end)
        if not cb_ok then
            state.failed=true
            log('could not attach callback for '..key..': '..tostring(cb_reason))
            return
        end
    end

    state.registered=true
    log('registered '..tostring(#OPTIONS)..' settings in 2 Mod Options Menu categories; INI is authoritative')
end

local previous_update=rawget(_G,'update')
local unpack_results=table.unpack or unpack
local function pack_results(...) return {n=select('#',...),...} end

update=function(...)
    local results
    if type(previous_update)=='function' then results=pack_results(previous_update(...)) else results={n=0} end
    state.frames=state.frames+1
    if not state.registered and not state.failed and (state.frames==1 or state.frames%60==0) then
        local ok,why=pcall(register_all)
        if not ok then state.failed=true; log('registration error: '..tostring(why)) end
    end
    if state.pending_count>0 then
        local ok,why=flush_pending()
        if not ok and state.frames%120==0 then log('waiting to save Mod Options changes: '..tostring(why)) end
    end
    return unpack_results(results,1,results.n)
end

log('optional Mod Options Menu bridge armed')
return state
