import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';

final users = [
  User(
    id: 'franca',
    name: 'Franca',
    avatarUrl: 'https://image.gala.de/22980002/t/Os/v4/w2048/r0/-/franca-lehfeldt-pferd.jpg',
  ),
  User(
    id: 'christian',
    name: 'Christian',
    avatarUrl: 'https://cdn.prod.www.spiegel.de/images/9fd2aa2f-01a2-4837-8875-c4ee51ad1c45_w1200_r1.33_fpx35_fpy23.jpg',
  ),
];

final currentUserProvider = StateProvider<User>((ref) => users[0]); 