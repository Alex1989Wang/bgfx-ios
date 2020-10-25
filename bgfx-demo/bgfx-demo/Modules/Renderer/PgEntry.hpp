//
//  PgEntry.hpp
//  PgImageAlgoResManager
//
//  Created by Camera360 on 2018/10/30.
//  Copyright © 2018 vstudio. All rights reserved.
//

#ifndef PgEntry_h
#define PgEntry_h

namespace bx { struct FileReaderI; struct FileWriterI; struct AllocatorI; }

#define ENTRY_DEFAULT_WIDTH  750
#define ENTRY_DEFAULT_HEIGHT 1334

#ifndef ENTRY_CONFIG_IMPLEMENT_DEFAULT_ALLOCATOR
#    define ENTRY_CONFIG_IMPLEMENT_DEFAULT_ALLOCATOR 1
#endif // ENTRY_CONFIG_IMPLEMENT_DEFAULT_ALLOCATOR

namespace entry
{
    bx::FileReaderI* getFileReader();
    bx::FileWriterI* getFileWriter();
    bx::AllocatorI*  getAllocator();
    
    void init();
    void unInit();
}


#endif /* PgEntry_h */
