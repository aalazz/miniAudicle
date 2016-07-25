//
//  ulib_motion.cpp
//  miniAudicle
//
//  Created by Spencer Salazar on 9/17/14.
//
//

#include "ulib_motion.h"
#include "chuck_vm.h"
#include "chuck_globals.h"
#include "util_buffers.h"

#import <CoreMotion/CoreMotion.h>
#import <CoreLocation/CoreLocation.h>

/* member vars for MotionMsg */
static t_CKUINT motionmsg_mvar_timestamp = 0;
static t_CKUINT motionmsg_mvar_type = 0;
static t_CKUINT motionmsg_mvar_x = 0;
static t_CKUINT motionmsg_mvar_y = 0;
static t_CKUINT motionmsg_mvar_z = 0;
static t_CKUINT motionmsg_mvar_heading = 0;
static t_CKUINT motionmsg_mvar_latitude = 0;
static t_CKUINT motionmsg_mvar_longitude = 0;

/* static vars for Motion types */
static t_CKINT MOTIONTYPE_NONE     = 0;
static t_CKINT MOTIONTYPE_ACCEL    = 1;
static t_CKINT MOTIONTYPE_GYRO     = 2;
static t_CKINT MOTIONTYPE_MAG      = 3;
static t_CKINT MOTIONTYPE_ATTITUDE = 4;
static t_CKINT MOTIONTYPE_HEADING  = 5;
static t_CKINT MOTIONTYPE_LOCATION = 6;

/* member functions for Motion */
CK_DLL_CTOR(motion_ctor);
CK_DLL_DTOR(motion_dtor);
CK_DLL_MFUN(motion_start);
CK_DLL_MFUN(motion_stop);
CK_DLL_MFUN(motion_stop_all);
CK_DLL_MFUN(motion_recv);

/* member vars for Motion */
static t_CKUINT motion_mvar_manager = 0;
static t_CKUINT motion_mvar_queue = 0;


t_CKBOOL motion_query( Chuck_Env *env )
{
    Chuck_DL_Func * func = NULL;
    
    // log
    EM_log( CK_LOG_INFO, "class 'Motion'" );
    
    std::string doc;
    
    // import
    doc = "Holds a single sample of sensor data. ";
    if( !type_engine_import_class_begin(env, "MotionMsg", "Object", env->global(),
                                        NULL, NULL, doc.c_str()))
        return FALSE;
    
    doc = "Type of the sensor data. ";
    motionmsg_mvar_type = type_engine_import_mvar( env, "int", "type", FALSE, doc.c_str() );
    if( motionmsg_mvar_type == CK_INVALID_OFFSET ) goto error;
    
    doc = "Time corresponding to this sample. ";
    motionmsg_mvar_timestamp = type_engine_import_mvar( env, "time", "timestamp", FALSE, doc.c_str() );
    if( motionmsg_mvar_timestamp == CK_INVALID_OFFSET ) goto error;
    
    doc = "x-coordinate of this sample. Valid for accelerometer, gyroscope, magnetometer, or attitude samples only.";
    motionmsg_mvar_x = type_engine_import_mvar( env, "float", "x", FALSE, doc.c_str() );
    if( motionmsg_mvar_x == CK_INVALID_OFFSET ) goto error;
    
    doc = "y-coordinate of this sample. Valid for accelerometer, gyroscope, magnetometer, or attitude samples only.";
    motionmsg_mvar_y = type_engine_import_mvar( env, "float", "y", FALSE, doc.c_str() );
    if( motionmsg_mvar_y == CK_INVALID_OFFSET ) goto error;
    
    doc = "z-coordinate of this sample. Valid for accelerometer, gyroscope, magnetometer, or attitude samples only.";
    motionmsg_mvar_z = type_engine_import_mvar( env, "float", "z", FALSE, doc.c_str() );
    if( motionmsg_mvar_z == CK_INVALID_OFFSET ) goto error;
    
    doc = "Heading of this sample, in degrees clockwise from magnetic north. Valid for compass heading samples only.";
    motionmsg_mvar_heading = type_engine_import_mvar( env, "float", "heading", FALSE, doc.c_str() );
    if( motionmsg_mvar_heading == CK_INVALID_OFFSET ) goto error;
    
    doc = "Latitude of this sample. Valid for location samples only.";
    motionmsg_mvar_latitude = type_engine_import_mvar( env, "float", "latitude", FALSE, doc.c_str() );
    if( motionmsg_mvar_latitude == CK_INVALID_OFFSET ) goto error;
    
    doc = "Longitude of this sample. Valid for location samples only.";
    motionmsg_mvar_longitude = type_engine_import_mvar( env, "float", "longitude", FALSE, doc.c_str() );
    if( motionmsg_mvar_longitude == CK_INVALID_OFFSET ) goto error;
    
    // end the class import
    type_engine_import_class_end( env );
    
    // import
    doc = "Provides data from the various sensors of the host mobile device.";
    if( !type_engine_import_class_begin(env, "Motion", "Event", env->global(),
                                        motion_ctor, motion_dtor, doc.c_str()))
        return FALSE;
    
    //
    doc = "No sensor type specified.";
    if( !type_engine_import_svar(env, "int", "NONE", TRUE,
                                 (t_CKUINT) &MOTIONTYPE_NONE, doc.c_str() ) )
        goto error;
    
    //
    doc = "Accelerometer.";
    if( !type_engine_import_svar(env, "int", "ACCEL", TRUE,
                                 (t_CKUINT) &MOTIONTYPE_ACCEL, doc.c_str() ) )
        goto error;
    
    //
    doc = "Gyroscope.";
    if( !type_engine_import_svar(env, "int", "GYRO", TRUE,
                                 (t_CKUINT) &MOTIONTYPE_GYRO, doc.c_str() ) )
        goto error;
    
    //
    doc = "Magnetometer.";
    if( !type_engine_import_svar(env, "int", "MAG", TRUE,
                                 (t_CKUINT) &MOTIONTYPE_MAG, doc.c_str() ) )
        goto error;
    
    //
    doc = "Attitude.";
    if( !type_engine_import_svar(env, "int", "ATTITUDE", TRUE,
                                 (t_CKUINT) &MOTIONTYPE_ATTITUDE, doc.c_str() ) )
        goto error;
    
    //
    doc = "Compass heading.";
    if( !type_engine_import_svar(env, "int", "HEADING", TRUE,
                                 (t_CKUINT) &MOTIONTYPE_HEADING, doc.c_str() ) )
        goto error;
    
    //
    doc = "Geographic location.";
    if( !type_engine_import_svar(env, "int", "LOCATION", TRUE,
                                 (t_CKUINT) &MOTIONTYPE_LOCATION, doc.c_str() ) )
        goto error;
    
    // private mvar
    motion_mvar_manager = type_engine_import_mvar( env, "int", "@mgr", FALSE, NULL );
    if( motion_mvar_manager == CK_INVALID_OFFSET ) goto error;
    
    // private mvar
    motion_mvar_queue = type_engine_import_mvar( env, "int", "@queue", FALSE, NULL );
    if( motion_mvar_queue == CK_INVALID_OFFSET ) goto error;
    
    // add start()
    doc = "Start generating input from the specified sensor. ";
    func = make_new_mfun( "int", "open", motion_start );
    func->add_arg("int", "type");
    func->doc = doc;
    if( !type_engine_import_mfun( env, func ) ) goto error;
    
    // add stop()
    doc = "Stop generating input from all sensors. ";
    func = make_new_mfun( "void", "close", motion_stop_all );
    func->doc = doc;
    if( !type_engine_import_mfun( env, func ) ) goto error;
    
    // add stop()
    doc = "Stop generating input from the specified sensor. ";
    func = make_new_mfun( "void", "close", motion_stop );
    func->add_arg("int", "type");
    func->doc = doc;
    if( !type_engine_import_mfun( env, func ) ) goto error;
    
    // add recv()
    doc = "Receive the next sample of sensor data. ";
    func = make_new_mfun( "int", "recv", motion_recv );
    func->add_arg("MotionMsg", "type");
    func->doc = doc;
    if( !type_engine_import_mfun( env, func ) ) goto error;
    
    // end the class import
    type_engine_import_class_end( env );
    
    return TRUE;
    
error:
    
    // end the class import
    type_engine_import_class_end( env );
    
    return FALSE;
}

struct MotionMsg
{
    MotionMsg()
    {
        memset(this, 0, sizeof(MotionMsg));
        type = MOTIONTYPE_NONE;
    }
    
    MotionMsg(t_CKINT _type, t_CKTIME _timestamp, t_CKFLOAT _x, t_CKFLOAT _y, t_CKFLOAT _z)
    {
        type = _type;
        timestamp = _timestamp;
        x = _x;
        y = _y;
        z = _z;
    }
    
    MotionMsg(t_CKINT _type, t_CKTIME _timestamp, t_CKFLOAT _heading)
    {
        type = _type;
        timestamp = _timestamp;
        heading = _heading;
    }
    
    MotionMsg(t_CKINT _type, t_CKTIME _timestamp, t_CKFLOAT _latitude, t_CKFLOAT _longitude)
    {
        type = _type;
        timestamp = _timestamp;
        location.latitude = _latitude;
        location.longitude = _longitude;
    }
    
    t_CKINT type;
    t_CKTIME timestamp;
    
    union
    {
        struct
        {
            t_CKFLOAT x, y, z;
        };
        
        t_CKFLOAT heading;
        
        struct
        {
            t_CKFLOAT latitude, longitude;
        } location;
    };
};

@interface mAMotionManager : NSObject<CLLocationManagerDelegate>

- (id)initWithVM:(Chuck_VM *)vm;

- (void)startAccelerometer:(Chuck_Event *)event toQueue:(CircularBuffer<MotionMsg> *)queue;
- (void)startGyroscope:(Chuck_Event *)event toQueue:(CircularBuffer<MotionMsg> *)queue;
- (void)startMagnetometer:(Chuck_Event *)event toQueue:(CircularBuffer<MotionMsg> *)queue;
- (void)startAttitude:(Chuck_Event *)event toQueue:(CircularBuffer<MotionMsg> *)queue;
- (void)startHeading:(Chuck_Event *)event toQueue:(CircularBuffer<MotionMsg> *)queue;
- (void)startLocation:(Chuck_Event *)event toQueue:(CircularBuffer<MotionMsg> *)queue;

- (void)stop:(Chuck_Event *)event onCompletion:(void (^)())completion;
- (void)enqueueToThread:(void (^)())block;

@end

mAMotionManager *g_motionManager = nil;

CK_DLL_CTOR(motion_ctor)
{
    if(g_motionManager == nil)
        g_motionManager = [[mAMotionManager alloc] initWithVM:SHRED->vm_ref];
    OBJ_MEMBER_INT(SELF, motion_mvar_queue) = (t_CKINT) new CircularBuffer<MotionMsg>(32);
}

CK_DLL_DTOR(motion_dtor)
{
    assert(g_motionManager);
    
    CircularBuffer<MotionMsg> *queue = (CircularBuffer<MotionMsg> *) OBJ_MEMBER_INT(SELF, motion_mvar_queue);
    OBJ_MEMBER_INT(SELF, motion_mvar_queue) = NULL;
    
    [g_motionManager stop:(Chuck_Event *)SELF onCompletion:^{
        if(queue)
            delete queue;
    }];
}

CK_DLL_MFUN(motion_start)
{
    assert(g_motionManager);
    
    CircularBuffer<MotionMsg> *queue = (CircularBuffer<MotionMsg> *) OBJ_MEMBER_INT(SELF, motion_mvar_queue);
    t_CKINT type = GET_NEXT_INT(ARGS);
    
    if(type == MOTIONTYPE_ACCEL)
        [g_motionManager startAccelerometer:(Chuck_Event *)SELF toQueue:queue];
    else if(type == MOTIONTYPE_GYRO)
        [g_motionManager startGyroscope:(Chuck_Event *)SELF toQueue:queue];
    else if(type == MOTIONTYPE_MAG)
        [g_motionManager startMagnetometer:(Chuck_Event *)SELF toQueue:queue];
    else if(type == MOTIONTYPE_ATTITUDE)
        [g_motionManager startAttitude:(Chuck_Event *)SELF toQueue:queue];
    else if(type == MOTIONTYPE_HEADING)
        [g_motionManager startHeading:(Chuck_Event *)SELF toQueue:queue];
    else if(type == MOTIONTYPE_LOCATION)
        [g_motionManager startLocation:(Chuck_Event *)SELF toQueue:queue];
    
    RETURN->v_int = 1;
}

CK_DLL_MFUN(motion_stop)
{
    [g_motionManager stop:(Chuck_Event *)SELF onCompletion:nil];
}

CK_DLL_MFUN(motion_stop_all)
{
    [g_motionManager stop:(Chuck_Event *)SELF onCompletion:nil];
}

CK_DLL_MFUN(motion_recv)
{
    Chuck_Object *msgobj = GET_NEXT_OBJECT(ARGS);
    CircularBuffer<MotionMsg> *queue = (CircularBuffer<MotionMsg> *) OBJ_MEMBER_INT(SELF, motion_mvar_queue);

    MotionMsg msg;
    
    size_t gotit = queue->get(msg);
    if(gotit)
    {
        OBJ_MEMBER_INT(msgobj, motionmsg_mvar_type) = msg.type;
        OBJ_MEMBER_TIME(msgobj, motionmsg_mvar_timestamp) = msg.timestamp;
        
        if(msg.type == MOTIONTYPE_ACCEL || msg.type == MOTIONTYPE_GYRO ||
           msg.type == MOTIONTYPE_MAG || msg.type == MOTIONTYPE_ATTITUDE)
        {
            OBJ_MEMBER_FLOAT(msgobj, motionmsg_mvar_x) = msg.x;
            OBJ_MEMBER_FLOAT(msgobj, motionmsg_mvar_y) = msg.y;
            OBJ_MEMBER_FLOAT(msgobj, motionmsg_mvar_z) = msg.z;
        }
        else if(msg.type == MOTIONTYPE_HEADING)
        {
            OBJ_MEMBER_FLOAT(msgobj, motionmsg_mvar_heading) = msg.heading;
        }
        else if(msg.type == MOTIONTYPE_LOCATION)
        {
            OBJ_MEMBER_FLOAT(msgobj, motionmsg_mvar_latitude) = msg.location.latitude;
            OBJ_MEMBER_FLOAT(msgobj, motionmsg_mvar_longitude) = msg.location.longitude;
        }
    }
    
    RETURN->v_int = gotit;
}


@interface mAMotionManager ()
{
    dispatch_queue_t _dispatchQueue;
    NSOperationQueue *_queue;
    Chuck_VM *_vm;
    CBufferSimple *_eventBuffer;
    
    std::map<t_CKINT, std::list<Chuck_Event *> > _listeners;
    std::map<Chuck_Event *, CircularBuffer<MotionMsg> *> _messageQueue;
}

@property (strong, nonatomic) CMMotionManager *motionManager;
@property (strong, nonatomic) CLLocationManager *locationManager;

- (void)_updateAccelerometer:(CMAccelerometerData *)accelerometerData;
- (void)_updateGyroscope:(CMGyroData *)gyroData;
- (void)_updateMagnetometer:(CMMagnetometerData *)magData;
- (void)_updateAttitude:(CMDeviceMotion *)motionData;

@end


@implementation mAMotionManager

- (CMMotionManager *)motionManager
{
    if(_motionManager == nil)
        _motionManager = [CMMotionManager new];
    return _motionManager;
}

- (CLLocationManager *)locationManager
{
    if(_locationManager == nil)
    {
        _locationManager = [CLLocationManager new];
        _locationManager.delegate = self;
    }
    
    return _locationManager;
}

- (id)initWithVM:(Chuck_VM *)vm;
{
    if(self = [super init])
    {
        _dispatchQueue = dispatch_queue_create("mAMotionManager", DISPATCH_QUEUE_SERIAL);
        _queue = [NSOperationQueue new];
        [_queue setUnderlyingQueue:_dispatchQueue];
        
        _vm = vm;
        _eventBuffer = vm->create_event_buffer();
    }
    
    return self;
}

- (void)startAccelerometer:(Chuck_Event *)event toQueue:(CircularBuffer<MotionMsg> *)queue
{
    dispatch_async(_dispatchQueue, ^{
        _listeners[MOTIONTYPE_ACCEL].push_back(event);
        _messageQueue[event] = queue;
    });
    
    if(!self.motionManager.accelerometerActive)
    {
        [self.motionManager startAccelerometerUpdatesToQueue:_queue
                                                 withHandler:^(CMAccelerometerData * _Nullable accelerometerData,
                                                               NSError * _Nullable error) {
                                                     [self _updateAccelerometer:accelerometerData];
                                                 }];
    }
}

- (void)_updateAccelerometer:(CMAccelerometerData *)accelerometerData
{
    CMAcceleration accel = accelerometerData.acceleration;
    MotionMsg msg(MOTIONTYPE_ACCEL, 0, accel.x, accel.y, accel.z);
    
    for(auto event : _listeners[MOTIONTYPE_ACCEL])
    {
        if(_messageQueue.count(event) != 0 && _messageQueue[event])
            _messageQueue[event]->put(msg);
        event->queue_broadcast(_eventBuffer);
    }
}

- (void)startGyroscope:(Chuck_Event *)event toQueue:(CircularBuffer<MotionMsg> *)queue
{
    dispatch_async(_dispatchQueue, ^{
        _listeners[MOTIONTYPE_GYRO].push_back(event);
        _messageQueue[event] = queue;
    });
    
    if(!self.motionManager.gyroActive)
    {
        [self.motionManager startGyroUpdatesToQueue:_queue
                                        withHandler:^(CMGyroData * _Nullable gyroData, NSError * _Nullable error) {
                                            [self _updateGyroscope:gyroData];
                                        }];
    }
}

- (void)_updateGyroscope:(CMGyroData *)gyroData
{
    CMRotationRate rot = gyroData.rotationRate;
    MotionMsg msg(MOTIONTYPE_GYRO, 0, rot.x, rot.y, rot.z);
    
    for(auto event : _listeners[MOTIONTYPE_GYRO])
    {
        if(_messageQueue.count(event) != 0 && _messageQueue[event])
            _messageQueue[event]->put(msg);
        event->queue_broadcast(_eventBuffer);
    }
}

- (void)startMagnetometer:(Chuck_Event *)event toQueue:(CircularBuffer<MotionMsg> *)queue
{
    dispatch_async(_dispatchQueue, ^{
        _listeners[MOTIONTYPE_MAG].push_back(event);
        _messageQueue[event] = queue;
    });
    
    if(!self.motionManager.magnetometerActive)
    {
        [self.motionManager startMagnetometerUpdatesToQueue:_queue
                                                withHandler:^(CMMagnetometerData * _Nullable magnetometerData, NSError * _Nullable error) {
                                                    [self _updateMagnetometer:magnetometerData];
                                                }];
    }
}

- (void)_updateMagnetometer:(CMMagnetometerData *)magData
{
    CMMagneticField mag = magData.magneticField;
    MotionMsg msg(MOTIONTYPE_MAG, 0, mag.x, mag.y, mag.z);
    
    for(auto event : _listeners[MOTIONTYPE_MAG])
    {
        if(_messageQueue.count(event) != 0 && _messageQueue[event])
            _messageQueue[event]->put(msg);
        event->queue_broadcast(_eventBuffer);
    }
}

- (void)startAttitude:(Chuck_Event *)event toQueue:(CircularBuffer<MotionMsg> *)queue
{
    dispatch_async(_dispatchQueue, ^{
        _listeners[MOTIONTYPE_ATTITUDE].push_back(event);
        _messageQueue[event] = queue;
    });
    
    if(!self.motionManager.deviceMotionActive)
    {
        [self.motionManager startDeviceMotionUpdatesToQueue:_queue
                                                withHandler:^(CMDeviceMotion * _Nullable motion, NSError * _Nullable error) {
                                                    [self _updateAttitude:motion];
                                                }];
    }
}

- (void)_updateAttitude:(CMDeviceMotion *)motionData
{
    CMAttitude *att = motionData.attitude;
    MotionMsg msg(MOTIONTYPE_ATTITUDE, 0, att.roll, att.pitch, att.yaw);
    
    for(auto event : _listeners[MOTIONTYPE_ATTITUDE])
    {
        if(_messageQueue.count(event) != 0 && _messageQueue[event])
            _messageQueue[event]->put(msg);
        event->queue_broadcast(_eventBuffer);
    }
}

- (void)startHeading:(Chuck_Event *)event toQueue:(CircularBuffer<MotionMsg> *)queue
{
    dispatch_async(_dispatchQueue, ^{
        _listeners[MOTIONTYPE_HEADING].push_back(event);
        _messageQueue[event] = queue;
    });
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.locationManager startUpdatingHeading];
    });
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
    dispatch_async(_dispatchQueue, ^{
        MotionMsg msg(MOTIONTYPE_HEADING, 0, newHeading.magneticHeading);
        
        for(auto event : _listeners[MOTIONTYPE_HEADING])
        {
            if(_messageQueue.count(event) != 0 && _messageQueue[event])
                _messageQueue[event]->put(msg);
            event->queue_broadcast(_eventBuffer);
        }
    });
}

- (BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager
{
    return YES;
}

- (void)startLocation:(Chuck_Event *)event toQueue:(CircularBuffer<MotionMsg> *)queue
{
    dispatch_async(_dispatchQueue, ^{
        _listeners[MOTIONTYPE_LOCATION].push_back(event);
        _messageQueue[event] = queue;
    });
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined)
            [self.locationManager requestWhenInUseAuthorization];
        else
        {
            [self.locationManager startUpdatingLocation];
            [self.locationManager requestLocation];
        }
    });
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if(status == kCLAuthorizationStatusAuthorizedAlways ||
       status == kCLAuthorizationStatusAuthorizedWhenInUse)
    {
        [self.locationManager startUpdatingLocation];
        [self.locationManager requestLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    CLLocation *location = [locations lastObject];
    CLLocationCoordinate2D coord = location.coordinate;
    
    dispatch_async(_dispatchQueue, ^{
        MotionMsg msg(MOTIONTYPE_LOCATION, 0, coord.latitude, coord.longitude);
        
        for(auto event : _listeners[MOTIONTYPE_LOCATION])
        {
            if(_messageQueue.count(event) != 0 && _messageQueue[event])
                _messageQueue[event]->put(msg);
            event->queue_broadcast(_eventBuffer);
        }
    });
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"locationManager:didFailWithError: %@", error);
}

- (void)stop:(Chuck_Event *)event onCompletion:(void (^)())completion
{
    dispatch_async(_dispatchQueue, ^{
        for(auto _typeListener : _listeners)
            _typeListener.second.remove(event);
        _messageQueue.erase(event);
        
        if(completion)
            completion();
        
        if(_listeners.count(MOTIONTYPE_ACCEL) && _listeners[MOTIONTYPE_ACCEL].size() == 0)
            [self.motionManager stopAccelerometerUpdates];
        if(_listeners.count(MOTIONTYPE_GYRO) && _listeners[MOTIONTYPE_GYRO].size() == 0)
            [self.motionManager stopGyroUpdates];
        if(_listeners.count(MOTIONTYPE_MAG) && _listeners[MOTIONTYPE_MAG].size() == 0)
            [self.motionManager stopMagnetometerUpdates];
        if(_listeners.count(MOTIONTYPE_ATTITUDE) && _listeners[MOTIONTYPE_ATTITUDE].size() == 0)
            [self.motionManager stopDeviceMotionUpdates];
        if(_listeners.count(MOTIONTYPE_HEADING) && _listeners[MOTIONTYPE_HEADING].size() == 0)
            [self.locationManager stopUpdatingHeading];
        if(_listeners.count(MOTIONTYPE_LOCATION) && _listeners[MOTIONTYPE_LOCATION].size() == 0)
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.locationManager stopUpdatingLocation];
            });
    });
}

- (void)enqueueToThread:(void (^)())block
{
    assert(block != nil);
    dispatch_async(_dispatchQueue, block);
}

@end



