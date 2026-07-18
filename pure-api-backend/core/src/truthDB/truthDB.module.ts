import { Global, Module } from '@nestjs/common';
import { TruthDBService } from './truthDB.service';

@Global()
@Module({
  providers: [TruthDBService],
  exports: [TruthDBService],
})
export class TruthDBModule {}
