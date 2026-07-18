import { Module } from '@nestjs/common';
import { TruthDBModule } from './truthDB/truthDB.module';

@Module({
  imports: [TruthDBModule],
  controllers: [],
  providers: [],
})
export class AppModule {}
