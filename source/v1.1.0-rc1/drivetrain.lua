-- HD2-Addon: mods/digitalkaizer/better_tanks_drivetrain
-- HD2 Better Tanks v1.1.0 RC1
-- Runtime Havok drivetrain tuning for tracked player vehicles.
-- Exact-build guarded: refuses to write when the supported executable layout is not detected.

if rawget(_G,'DigitalKaizerBetterTanksDrivetrain') then return end

local Common=require('mods/digitalkaizer/better_tanks_common')
local log=function(msg) Common.log('Drivetrain',msg) end

local DEFAULTS={
    clutch_delay=0.0,
    speed_scale=1.2,
    turn_scale=1.2,
}
local MAP={
    tracked_clutch_delay_seconds='clutch_delay',
    tracked_top_speed_scale='speed_scale',
    tracked_driving_turn_scale='turn_scale',
}
local function valid(k,v)
    if k=='clutch_delay' then return v>=0 and v<=10 end
    if k=='speed_scale' or k=='turn_scale' then return v>=0.5 and v<=2.0 end
    return false
end
local CFG=Common.read_number_map(MAP,DEFAULTS,valid)

local state={
    version='better-tanks-v1.1.0-rc1',
    phase='starting',
    frames=0,
    sweeps=0,
    tracked_seen=0,
    applied=0,
    verified=0,
    rejected=0,
    errors=0,
    clutch_delay=CFG.clutch_delay,
    speed_scale=CFG.speed_scale,
    turn_scale=CFG.turn_scale,
    last='none',
}
rawset(_G,'DigitalKaizerBetterTanksDrivetrain',state)

local loader=rawget(_G,'CowboyBingusModLoader')
if type(loader)~='table' or type(loader.api)~='number' or loader.api<1
   or type(loader.version)~='number' or loader.version<15 then
    state.phase='rejected'; state.last='Bingus Shared Loader v15+ / API 1 required'; log(state.last); return
end

local ok_ffi,ffi=pcall(require,'ffi')
if not ok_ffi or not ffi.abi('win') or not ffi.abi('64bit') then
    state.phase='rejected'; state.last='Windows x64 LuaJIT FFI required'; log(state.last); return
end

ffi.cdef[[
void *GetModuleHandleA(const char *name);
void *GetCurrentProcess(void);
int ReadProcessMemory(void *process,const void *address,void *buffer,size_t size,size_t *read);
typedef struct {
    void *base; void *allocation_base; uint32_t allocation_protection;
    uint16_t partition; uint16_t reserved; size_t size;
    uint32_t state; uint32_t protection; uint32_t type;
} BetterTanksMemoryRegion;
size_t VirtualQuery(const void *address,void *region,size_t size);
]]

local kernel=ffi.load('kernel32')
local process=kernel.GetCurrentProcess()
local U8=ffi.typeof('uint8_t *')
local query_region=ffi.cast('size_t (*)(const void *, void *, size_t)',kernel.VirtualQuery)
local unpack_values=table.unpack or unpack
local function pack_values(...) return {n=select('#',...),...} end
local function addr(v) return tonumber(ffi.cast('uintptr_t',v)) end
local function read(p,n)
    if not p or n<=0 or n>0x20000 then return nil end
    local b=ffi.new('uint8_t[?]',n); local got=ffi.new('size_t[1]')
    if kernel.ReadProcessMemory(process,p,b,n,got)==0 or tonumber(got[0])~=n then return nil end
    return ffi.string(b,n)
end
local function u8(s,o) if not s or o<0 or o>=#s then return nil end return s:byte(o+1) end
local function u16(s,o)
    if not s or o<0 or o+2>#s then return nil end
    local a,b=s:byte(o+1,o+2); return a+b*256
end
local function u32(s,o)
    if not s or o<0 or o+4>#s then return nil end
    local a,b,c,d=s:byte(o+1,o+4); return a+b*256+c*65536+d*16777216
end
local function u64(s,o)
    if not s or o<0 or o+8>#s then return nil end
    local x=ffi.new('uint64_t[1]'); ffi.copy(x,s:sub(o+1,o+8),8); return x[0]
end
local function ptr(s,o)
    local v=u64(s,o or 0)
    if not v or v<0x10000 or v>=0x800000000000ULL then return nil end
    return ffi.cast(U8,v)
end
local function f32(s,o)
    if not s or o<0 or o+4>#s then return nil end
    local x=ffi.new('float[1]'); ffi.copy(x,s:sub(o+1,o+4),4); return tonumber(x[0])
end
local function writable(p,n)
    if not p or n<=0 then return false end
    local r=ffi.new('BetterTanksMemoryRegion[1]')
    if query_region(p,r,ffi.sizeof(r[0]))~=ffi.sizeof(r[0]) then return false end
    if r[0].state~=0x1000 or r[0].type~=0x20000 then return false end
    if r[0].protection~=4 and r[0].protection~=8 then return false end
    local available=tonumber(r[0].size)-(addr(p)-addr(r[0].base))
    return available>=n
end
local function vtable(p)
    local s=read(p,8); local v=s and u64(s,0); return v and tonumber(v) or nil
end
local function write_float(p,value)
    if addr(p)%4~=0 or not writable(p,4) then return false,'not_private_rw' end
    ffi.cast('float *',p)[0]=value
    local back=f32(read(p,4),0)
    if not back or math.abs(back-value)>math.max(1e-6,math.abs(value)*1e-6) then return false,'readback' end
    return true,back
end

-- Supported executable: output20260926.
local EXPECT_TS=0x6AB382E4
local EXPECT_IMAGE=0x39F1000
local POOL_TABLE_RVA=0x27C5B60
local VT_INSTANCE_RVA=0x14AD290
local VT_ENGINE_INSTANCE_RVA=0x16A1948
local VT_TRANS_RVA=0x14AAAC8
local VT_ENGINE_RVA=0x14B0FA0
local VT_STEER_RVA=0x14A1A30

local exe
local ok_gate,gate_err=pcall(function()
    local m=assert(kernel.GetModuleHandleA(nil),'process image unavailable')
    exe=ffi.cast(U8,m)
    local dos=assert(read(exe,0x100),'DOS header unreadable')
    assert(dos:sub(1,2)=='MZ','MZ missing')
    local peoff=assert(u32(dos,0x3C),'PE offset missing')
    local pe=assert(read(exe+peoff,0x100),'PE header unreadable')
    assert(pe:sub(1,4)=='PE\0\0','PE signature mismatch')
    assert(u16(pe,24)==0x20B,'not PE32+')
    local ts=u32(pe,8); local size=u32(pe,24+56)
    assert(ts==EXPECT_TS and size==EXPECT_IMAGE,
        string.format('unsupported exe ts=0x%X size=0x%X',ts or 0,size or 0))
end)
if not ok_gate then
    state.phase='rejected'; state.last=tostring(gate_err); log(state.last); return
end

local VT_INSTANCE=addr(exe)+VT_INSTANCE_RVA
local VT_ENGINE_INSTANCE=addr(exe)+VT_ENGINE_INSTANCE_RVA
local VT_TRANS=addr(exe)+VT_TRANS_RVA
local VT_ENGINE=addr(exe)+VT_ENGINE_RVA
local VT_STEER=addr(exe)+VT_STEER_RVA
local pool_table=exe+POOL_TABLE_RVA

-- field address -> {original,payload,vtable,object}
local leases={}
local function apply_field(object,vt_expected,offset,value,label)
    if not object or vtable(object)~=vt_expected then state.rejected=state.rejected+1; return false end
    local field=object+offset; local key=addr(field); local held=leases[key]
    if held then return true end
    local original=f32(read(field,4),0)
    if not original or original~=original then state.rejected=state.rejected+1; return false end
    local ok,back=write_float(field,value)
    if not ok then state.rejected=state.rejected+1; state.last=label..':'..tostring(back); return false end
    leases[key]={original=original,payload=back,vtable=vt_expected,object=addr(object)}
    state.applied=state.applied+1; state.verified=state.verified+1
    state.last=string.format('%s %.4f->%.4f',label,original,back)
    return true
end
local function scale_field(object,vt_expected,offset,scale,divide,label,lo,hi)
    if not object or vtable(object)~=vt_expected then state.rejected=state.rejected+1; return false end
    local field=object+offset; local key=addr(field); if leases[key] then return true end
    local original=f32(read(field,4),0)
    if not original or original~=original or original<lo or original>hi then state.rejected=state.rejected+1; return false end
    if math.abs(scale-1.0)<1e-6 then return true end
    local value=divide and (original/scale) or (original*scale)
    return apply_field(object,vt_expected,offset,value,label)
end

local bitlib=rawget(_G,'bit') or require('bit')
local function band32(a,b) local r=bitlib.band(a,b); if r<0 then r=r+4294967296 end; return r end
local function valid_key(key,index,shard,mask,flags)
    if not key or key==0 then return false end
    if math.floor(key/0x40000000)~=shard then return false end
    if band32(key,flags)==0 then return false end
    return band32(key,mask)==index
end

local function inspect_slot(slot,key)
    local object=slot
    local inst=ptr(read(object+0x18,8),0)
    if not inst then return nil end
    local iv=vtable(inst)
    if iv~=VT_INSTANCE and iv~=VT_ENGINE_INSTANCE then return nil end
    local ib=read(inst,0x60); if not ib then return nil end
    local data=ptr(ib,0x38); local steering=ptr(ib,0x48); local engine=ptr(ib,0x50); local trans=ptr(ib,0x58)
    if not data or not trans or vtable(trans)~=VT_TRANS then return nil end
    local db=read(data+0x1DC,2); local tracks=db and u8(db,0)
    if tracks~=1 then return nil end
    local tb=read(trans,0x40); if not tb then return nil end
    local clutch=f32(tb,0x28); local gears=u32(tb,0x38)
    if not clutch or clutch~=clutch or not gears or gears<1 or gears>64 then return nil end
    return {handle=key,trans=trans,engine=engine,steering=steering,clutch=clutch}
end

local function apply_vehicle(v)
    state.tracked_seen=state.tracked_seen+1
    -- Clutch delay is an absolute seconds value.
    if v.clutch>=0 and v.clutch<=10 and math.abs(v.clutch-CFG.clutch_delay)>1e-6 then
        apply_field(v.trans,VT_TRANS,0x28,CFG.clutch_delay,'clutch_delay')
    end
    -- Gearing / torque pair: ratio is divided while max torque is multiplied by the same scale.
    scale_field(v.trans,VT_TRANS,0x20,CFG.speed_scale,true,'primary_ratio',0.5,200)
    scale_field(v.engine,VT_ENGINE,0x24,CFG.speed_scale,false,'max_torque',1,1000000)
    -- Havok driving-turn envelope. Neutral/pivot turn cap is intentionally untouched.
    scale_field(v.steering,VT_STEER,0x18,CFG.turn_scale,false,'steering_max_angle',0.01,1.2)
    scale_field(v.steering,VT_STEER,0x1C,CFG.turn_scale,false,'steering_full_angle_speed',0.1,200)
end

local function sweep()
    local found=0
    for shard=0,3 do
        local pool=ptr(read(pool_table+shard*8,8),0)
        if pool then
            local hdr=read(pool,0x38)
            local base=hdr and ptr(hdr,0)
            local stride=hdr and u16(hdr,0x1C)
            local keyoff=hdr and u8(hdr,0x1E)
            local objoff=hdr and u8(hdr,0x1F)
            local count=hdr and u32(hdr,0x24)
            local mask=hdr and u32(hdr,0x28)
            local flags=hdr and u32(hdr,0x34)
            if base and stride and stride>=8 and stride<=0x1000 and count and count<=0x10000 and keyoff and objoff and mask and flags then
                for i=0,count-1 do
                    local s=read(base+stride*i,stride)
                    local key=s and u32(s,keyoff)
                    if key and valid_key(key,i,shard,mask,flags) then
                        local v=inspect_slot(base+stride*i+objoff,key)
                        if v then found=found+1; apply_vehicle(v) end
                    end
                end
            end
        end
    end
    state.sweeps=state.sweeps+1
    state.phase='steady'
    state.last='sweep tracked='..tostring(found)..' applied='..tostring(state.verified)
end

local function restore_all()
    for key,l in pairs(leases) do
        local object=ffi.cast(U8,l.object)
        local field=ffi.cast(U8,key)
        if vtable(object)==l.vtable and writable(field,4) then
            local cur=f32(read(field,4),0)
            if cur and math.abs(cur-l.payload)<=math.max(1e-6,math.abs(l.payload)*1e-6) then
                ffi.cast('float *',field)[0]=l.original
            end
        end
        leases[key]=nil
    end
end

local previous_update,previous_shutdown=update,shutdown
if type(previous_update)~='function' then
    state.phase='rejected'; state.last='game update callback unavailable'; log(state.last); return
end

local retired=false
local my_update
my_update=function(...)
    if retired then return previous_update(...) end
    local results=pack_values(pcall(previous_update,...))
    if not results[1] then retired=true; pcall(restore_all); error(results[2],0) end
    state.frames=state.frames+1
    if state.frames==120 or (state.frames>120 and state.frames%120==0) then
        local ok,why=pcall(sweep)
        if not ok then
            state.errors=state.errors+1; state.last='sweep error: '..tostring(why); log(state.last)
            if state.errors>=3 then retired=true; pcall(restore_all); state.phase='rejected' end
        end
    end
    return unpack_values(results,2,results.n)
end
update=my_update

shutdown=function(...)
    retired=true; pcall(restore_all); state.phase='stopped'
    if update==my_update then update=previous_update end
    if previous_shutdown then return previous_shutdown(...) end
end

state.phase='waiting_for_tracked_vehicle'
log(string.format('installed clutch=%.3f speed_scale=%.3f turn_scale=%.3f',CFG.clutch_delay,CFG.speed_scale,CFG.turn_scale))
